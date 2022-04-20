# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later

module QueryRecurringDonations

  # Calculate a nonprofit's total recurring donations
  def self.monthly_total(np_id)
    Qx.select("coalesce(sum(amount), 0) AS sum")
      .from("recurring_donations")
      .where(nonprofit_id: np_id)
      .and_where(is_external_active_clause('recurring_donations'))
      .execute.first['sum']
  end


  # Fetch a single recurring donation for its edit page
  def self.fetch_for_edit(id)
    recurring_donation = Psql.execute(
        Qexpr.new.select(
          "recurring_donations.*",
          "nonprofits.id AS nonprofit_id",
          "nonprofits.name AS nonprofit_name",
          "cards.name AS card_name"
        ).from('recurring_donations')
         .left_outer_join('donations', 'donations.id=recurring_donations.donation_id')
         .left_outer_join('cards', 'donations.card_id=cards.id')
         .left_outer_join('nonprofits', 'nonprofits.id=recurring_donations.nonprofit_id')
         .where('recurring_donations.id=$id', id: id)
      ).first

    return recurring_donation if !recurring_donation || !recurring_donation['id']

    supporter = Psql.execute(
      Qexpr.new.select('*')
      .from('supporters')
      .where('id=$id', id: recurring_donation['supporter_id'])
    ).first

    nonprofit = Nonprofit.find(recurring_donation['nonprofit_id'])

    return {
      'recurring_donation' => recurring_donation,
      'supporter' => supporter,
      'nonprofit' => nonprofit
    }
  end


  # Construct a full query for the dashboard/export listings
  def self.full_search_expr(np_id, query)
    include_last_failed_charge = !!query[:include_last_failed_charge]
    expr = Qexpr.new
      .from('recurring_donations')
      .left_outer_join('supporters', 'supporters.id=recurring_donations.supporter_id')
      .join('donations', 'donations.id=recurring_donations.donation_id')
      .left_outer_join('charges paid_charges', 'paid_charges.donation_id=donations.id')
      .left_outer_join('misc_recurring_donation_infos',
      'misc_recurring_donation_infos.recurring_donation_id = recurring_donations.id')
      .where('recurring_donations.nonprofit_id=$id', id: np_id.to_i)

    if include_last_failed_charge
      expr = expr.left_outer_join("(SELECT created_at, donation_id FROM charges WHERE charges.status = 'failed') AS failed_charges", 'failed_charges.donation_id = donations.id')
    end

    failed_or_active_clauses = []

    if query.key?(:active_and_not_failed)
      clause = query[:active_and_not_failed] ? is_external_active_clause('recurring_donations') : is_external_cancelled_clause('recurring_donations')
      failed_or_active_clauses.push("(#{clause})")
    end

    if query.key?(:active)
      clause = query[:active] ? is_active_clause('recurring_donations') : is_cancelled_clause('recurring_donations')
      failed_or_active_clauses.push("(#{clause})")
    end

    if query.key?(:failed)
      clause = query[:failed] ? is_failed_clause('recurring_donations') : is_not_failed_clause('recurring_donations')
      failed_or_active_clauses.push("(#{clause})")
    end

    if (failed_or_active_clauses.any?)
      expr = expr.where("#{failed_or_active_clauses.join(' OR ')}")
    end

    if include_last_failed_charge && query.key?(:from_date) && query.key?(:before_date)
      expr = expr.where(
        'failed_charges.created_at >= $from_date
        AND failed_charges.created_at < $before_date',
        { from_date: query[:from_date], before_date: query[:before_date] }
      )
    end

      expr = expr.where("paid_charges.id IS NULL OR paid_charges.status != 'failed'")
      .group_by('recurring_donations.id')
      .order_by('recurring_donations.created_at')
    if query[:cancelled_at_gt_or_equal].present?
      expr = expr.where('recurring_donations.cancelled_at >= $date', date: query[:cancelled_at_gt_or_equal])
    end

    if query[:cancelled_at_lt].present?
      expr = expr.where('recurring_donations.cancelled_at < $date', date: query[:cancelled_at_lt])
    end

    if query[:search].present?
      matcher = "%#{query[:search].downcase.split(' ').join('%')}%"
      expr = expr.where(%Q((
           lower(supporters.name) LIKE $name
        OR lower(supporters.email) LIKE $email
        OR recurring_donations.amount=$amount
        OR recurring_donations.id=$id
      )), {name: matcher, email: matcher, amount: query[:search].to_i, id: query[:search].to_i})
    end
    return expr
  end


  # Fetch the full table of results for the dashboard
  def self.full_list(np_id, query={})
    limit = 30
    offset = Qexpr.page_offset(limit, query[:page])
    expr = full_search_expr(np_id, query).select(
      'recurring_donations.start_date',
      'recurring_donations.interval',
      'recurring_donations.time_unit',
      'recurring_donations.n_failures',
      'recurring_donations.amount',
      'recurring_donations.id AS id',
      'MAX(supporters.email) AS email',
      'MAX(supporters.name) AS name',
      'MAX(supporters.id) AS supporter_id',
      'SUM(paid_charges.amount) AS total_given')
      .limit(limit).offset(offset)

    data = Psql.execute(expr)
    total_count = Psql.execute(
      Qexpr.new.select('COUNT(rds)')
      .from(full_search_expr(np_id, query).remove(:order_by).select('recurring_donations.id'), 'rds')
    ).first['count']
    total_amount = monthly_total(np_id)

    return {
      data: data,
      total_amount: total_amount,
      total_count: total_count,
      remaining: Qexpr.remaining_count(total_count, limit, query[:page]),
    }
  end

  def self.for_export_enumerable(npo_id, query, chunk_limit=15000)
    ParamValidation.new({npo_id: npo_id, query:query}, {npo_id: {required: true, is_int: true},
                                                        query: {required:true, is_hash: true}})

    return QexprQueryChunker.for_export_enumerable(chunk_limit) do |offset, limit, skip_header|
      get_chunk_of_export(npo_id, query, offset, limit, skip_header)
    end

  end

  def self.get_chunk_of_export(npo_id, query, offset=nil, limit=nil, skip_header=false )
    root_url = query[:root_url] || 'https://us.commitchange.com/'
    include_stripe_customer_id = query[:include_stripe_customer_id]
    include_last_failed_charge = !!query[:include_last_failed_charge]
    select_list = ['recurring_donations.created_at',
    '(recurring_donations.amount / 100.0)::money::text AS amount',
    "concat('Every ', recurring_donations.interval, ' ', recurring_donations.time_unit, '(s)') AS interval",
    '(SUM(paid_charges.amount) / 100.0)::money::text AS total_contributed',
    'MAX(campaigns.name) AS campaign_name',
    'MAX(supporters.name) AS supporter_name',
    'MAX(supporters.email) AS supporter_email',
    'MAX(supporters.phone) AS phone',
    'MAX(supporters.address) AS address',
    'MAX(supporters.city) AS city',
    'MAX(supporters.state_code) AS state',
    'MAX(supporters.zip_code) AS zip_code',
    'MAX(cards.name) AS card_name',
    'recurring_donations.id AS "Recurring Donation ID"',
    'MAX(donations.id) AS "Donation ID"',
    'MAX(donations.designation) AS "Designation"',
    'BOOL_OR(misc_recurring_donation_infos.fee_covered) AS "Fee Covered by Supporter"',
    "CASE WHEN #{is_cancelled_clause('recurring_donations')} 
      THEN 'cancelled' 
    WHEN #{is_failed_clause('recurring_donations')} 
      THEN 'failed' 
    ELSE 'active' END AS status",
    'recurring_donations.cancelled_at AS "Cancelled At"',
    "CASE WHEN #{is_active_clause('recurring_donations')} OR #{is_failed_clause('recurring_donations')} THEN concat('#{root_url}recurring_donations/', recurring_donations.id, '/edit?t=', recurring_donations.edit_token) ELSE '' END AS \"Donation Management Url\"",
    'MAX(recurring_donations.paydate) AS "Paydate"',
    'MAX(paid_charges.created_at) AS "Last Charge Succeeded"'
  ]

    if include_last_failed_charge
      select_list.push('MAX(failed_charges.created_at) AS "Last Failed Charge"')
    end

    if include_stripe_customer_id
      select_list.push 'MAX(cards.stripe_customer_id) AS "Stripe Customer ID"'
    end
    return QexprQueryChunker.get_chunk_of_query(offset, limit, skip_header) {
        full_search_expr(npo_id, query).select(select_list)
            .left_outer_join('campaigns' , 'campaigns.id=donations.campaign_id')
            .left_outer_join('cards', 'cards.id=donations.card_id')
            # .left_outer_join('misc_recurring_donation_infos', 'recurring_donations.id = misc_recurring_donation_infos.recurring_donation_id')
    }
  end


  def self.recurring_donations_without_cards
    RecurringDonation.active.includes(:card).includes(:charges).includes(:donation).includes(:nonprofit).includes(:supporter).where("cards.id IS NULL").order("recurring_donations.created_at DESC")
  end
  
  def self._splitting_rd_supporters_without_cards()
    supporters_with_valid_rds = []
    supporters_without_valid_rds = []
    send_to_wendy = []
    supporters_with_cardless_rds = recurring_donations_without_cards.map {|rd| rd.supporter}.uniq{|s| s.id}

    #does the supporter have even one rd with a valid card
    supporters_with_cardless_rds.each {|s|
      valid_rd = find_recurring_donation_with_a_card(s)
      # they have a recurring donation with a card for the same org
      if (valid_rd)
        if (s.recurring_donations.length > 2)
          #they have too many recurring_donations.  Send to wendy
          send_to_wendy.push(s)
        else
          # are the recurring_donations the same amount?
          if (s.recurring_donations[0].amount == s.recurring_donations[1].amount)
            supporters_with_valid_rds.push(s)
          else
            # they're not the same amount. We got no clue. Send to Wendy
            send_to_wendy.push(s)
          end
        end
      else
        # they have no other recurring donations
        supporters_without_valid_rds.push(s)
      end
    }

    return supporters_with_valid_rds, send_to_wendy, supporters_without_valid_rds
  end

  # @param [Array<Supporter>] wendy_list_of_supporters
  # @param [String] path
 # def self.create_wendy_csv(path, wendy_list_of_supporters)
 #   CSV.open(path, 'wb') {|csv|
 #     csv << ['supporter id',  'nonprofit id', 'supporter name', 'supporter address', 'supporter city', 'supporter state', 'supporter ZIP', 'supporter country', 'supporter phone', 'supporter email', 'supporter rd amounts']
 #     wendy_list_of_supporters.each { |s|
 #       amounts = '$'+ s.recurring_donations.active.collect {|rd| Format::Currency.cents_to_dollars(rd.amount)}.join(", $")
 #       csv << [s.id, s.nonprofit.id, s.name, s.address, s.city, s.state_code, s.zip_code, s.country, s.phone, s.email, amounts]
 #     }
 #   }
 # end

  # @param [Supporter] supporter
  def self.find_recurring_donation_with_a_card(supporter)
    supporter.recurring_donations.select{|rd|
      rd.donation != nil && rd.donation.card != nil}.first()
  end

  # Check if a single recdon is due -- used in PayRecurringDonation.with_stripe
  def self.is_due?(rd_id)
    Psql.execute(
      _all_that_are_due
      .where("recurring_donations.id=$id", id: rd_id)
    ).any?
  end


  # Sql partial expression
  # Select all due recurring donations
  # Can use this for all donations in the db, or extend the query for only those with a nonprofit_id, supporter_id, etc (see is_due?)
  # XXX horrendous conditional --what is wrong with me?
  def self._all_that_are_due
    now = Time.current
    Qexpr.new.select("recurring_donations.id")
    .from(:recurring_donations)
    .where("recurring_donations.active='t'")
    .where("coalesce(recurring_donations.n_failures, 0) < 3")
    .where("recurring_donations.start_date IS NULL OR recurring_donations.start_date <= $now", now: now)
    .where("recurring_donations.end_date IS NULL OR recurring_donations.end_date > $now", now: now)
    .where("(recurring_donation_holds.id IS NULL OR recurring_donation_holds.end_date IS NULL OR (recurring_donation_holds.end_date IS NOT NULL AND recurring_donation_holds.end_date <= $now))", now: now)
    .join('donations','recurring_donations.donation_id=donations.id and (donations.payment_provider IS NULL OR donations.payment_provider!=\'sepa\')')
    .left_outer_join( # Join the most recent paid charge
      Qexpr.new.select(:donation_id, "MAX(created_at) AS created_at")
      .from(:charges)
      .where("status != 'failed'")
      .group_by("donation_id")
      .as("last_charge"),
      "last_charge.donation_id=recurring_donations.donation_id"
    )
    .left_outer_join('recurring_donation_holds', 'recurring_donation_holds.recurring_donation_id = recurring_donations.id')
    .where(%Q(
      last_charge.donation_id IS NULL
      OR (
        (recurring_donations.time_unit != 'month' OR recurring_donations.interval != 1)
        AND last_charge.created_at + concat_ws(' ', recurring_donations.interval, recurring_donations.time_unit)::interval <= $now
      )
      OR (
        recurring_donations.time_unit='month' AND recurring_donations.interval=1
        AND (last_charge.created_at < $beginning_of_last_month)
        AND (recurring_donation_holds.end_date IS NULL OR recurring_donation_holds.end_date < $beginning_of_last_month)
        OR (
          recurring_donations.time_unit='month' AND recurring_donations.interval=1
          AND (last_charge.created_at < $beginning_of_month)
          AND (
            recurring_donations.paydate IS NOT NULL
            AND recurring_donations.paydate <= $today
            OR
            recurring_donations.paydate IS NULL
            AND extract(day FROM last_charge.created_at) <= $today
          )
        )
      )
    ), {
      now: now,
      beginning_of_month: now.beginning_of_month,
      beginning_of_last_month: (now - 1.month).beginning_of_month,
      today: now.day
    })
    .order_by('recurring_donations.created_at')
  end
  # Some general statistics for a nonprofit
  def self.overall_stats(np_id)
    return Psql.execute(
      Qexpr.new.from(:recurring_donations)
      .select(
        "money(avg(recurring_donations.amount) / 100.0) AS average",
        "money(coalesce(sum(rds_active.amount), 0) / 100.0) AS active_sum",
        "coalesce(count(rds_active), 0) AS active_count",
        "money(coalesce(sum(rds_inactive.amount), 0) / 100.0) AS inactive_sum",
        "coalesce(count(rds_inactive), 0) AS inactive_count",
        "money(coalesce(sum(rds_failed.amount), 0) / 100.0) AS failed_sum",
        "coalesce(count(rds_failed), 0) AS failed_count",
        "money(coalesce(sum(rds_cancelled.amount), 0) / 100.0) AS cancelled_sum",
        "coalesce(count(rds_cancelled), 0) AS cancelled_count"
      )
      .left_outer_join('recurring_donations rds_active', "rds_active.id=recurring_donations.id AND #{is_external_active_clause('rds_active')}")
      .left_outer_join('recurring_donations rds_inactive', "rds_inactive.id=recurring_donations.id AND #{is_external_cancelled_clause('rds_inactive')}")
      .left_outer_join('recurring_donations rds_failed', "rds_failed.id=recurring_donations.id AND #{is_failed_clause('rds_failed')}")
      .left_outer_join('recurring_donations rds_cancelled', "rds_cancelled.id=recurring_donations.id AND #{is_cancelled_clause('rds_cancelled')}")
      .where("recurring_donations.nonprofit_id=$id", id: np_id)
    ).first
  end

  # External active means what a user would consider active, i.e. a recurring donation that will be paid.
  # This means it hasn't be cancelled "active='t'" and that it hasn't failed 'n_failures < 3'
  def self.is_external_active_clause(field_for_rd)
    "#{is_active_clause(field_for_rd)} AND #{is_not_failed_clause(field_for_rd)} AND (#{field_for_rd}.end_date IS NULL OR #{field_for_rd}.end_date > '#{Time.current}')"
  end

  def self.is_external_cancelled_clause(field_for_rd)
    "((#{is_cancelled_clause(field_for_rd)} OR #{field_for_rd}.end_date <= '#{Time.current}') AND #{is_not_failed_clause(field_for_rd)})"
  end

  def self.is_active_clause(field_for_rd)
    "#{field_for_rd}.active='t'"
  end


  def self.is_cancelled_clause(field_for_rd)
    "NOT (#{is_active_clause(field_for_rd)})"
  end

  def self.is_not_failed_clause(field_for_rd)
    "coalesce(#{field_for_rd}.n_failures, 0) < 3"
  end

  def self.is_failed_clause(field_for_rd)
    "coalesce(#{field_for_rd}.n_failures, 0) >= 3"
  end

  def self.last_charge
    Qexpr.new.select(:donation_id, "MAX(created_at) AS created_at")
        .from(:charges)
        .where("status != 'failed'")
        .group_by("donation_id")
        .as("last_charge")
  end

  def self.export_for_transfer(nonprofit_id)
    items = RecurringDonation.where("nonprofit_id = ?", nonprofit_id).active.includes('supporter').includes('card').to_a
    output = items.map{|i| {supporter: i.supporter.id,
                            supporter_name: i.supporter.name,
                            supporter_email: i.supporter.email,
                            amount: i.amount,
    paydate: i.paydate,
    card: i.card.stripe_card_id}}
    return output.to_a
  end
end
