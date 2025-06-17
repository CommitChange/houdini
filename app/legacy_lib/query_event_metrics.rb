# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later

module QueryEventMetrics
  # For now limit to 1000
  QUERY_MAX_LIMIT = 1_000

  def self.with_event_ids(event_ids)
    return [] if event_ids.blank?

    events = Event.select(:id, :name, :venue_name, :address, :city, :state_code,
                         :zip_code, :start_datetime, :end_datetime, :organizer_email)
                  .where(id: event_ids)
                  .limit(QUERY_MAX_LIMIT)

    add_metrics_to_events(events)
  end

  def self.for_listings(id_type, profile_or_nonprofit_id, params)
    events = base_events(id_type, profile_or_nonprofit_id, params)
    return [] if events.blank?

    # Add metrics to the events
    add_metrics_to_events(events)
  end

  private

  def self.base_events(id_type, id, params)
    query = Event.select(:id, :name, :venue_name, :address, :city, :state_code,
                        :zip_code, :start_datetime, :end_datetime, :organizer_email)

    case id_type
    when "profile"
      query = query.where(profile_id: id)
    when "nonprofit"
      query = query.where(nonprofit_id: id)
    else
      raise "Unknown id_type #{id_type}"
    end

    if params["active"].present?
      query = query
        .where("end_datetime >= ?", Time.current)
        .where(published: true)
        .where("COALESCE(deleted, false) = false")
    elsif params["past"].present?
      query = query
        .where("end_datetime < ?", Time.current)
        .where(published: true)
        .where("COALESCE(deleted, false) = false")
    elsif params["unpublished"].present?
      query = query
        .where("COALESCE(published, false) = false")
        .where("COALESCE(deleted, false) = false")
    elsif params["deleted"].present?
      query = query.where(deleted: true)
    end

    query = query.order(end_datetime: :desc)
    query = query.limit(QUERY_MAX_LIMIT)

    query
  end

  def self.add_metrics_to_events(events)
    return [] if events.blank?

    event_ids = events.pluck(:id)

    ticket_metrics = ticket_metrics(event_ids)
    donation_metrics = donation_metrics(event_ids)
    payment_metrics = payment_metrics(event_ids)

    events.map do |event|
      build_event_result(event,
                         ticket_metrics[event.id],
                         donation_metrics[event.id],
                         payment_metrics[event.id])
    end
  end

  def self.build_event_result(event, tickets, donations, payments)
    tickets ||= { total: 0, checked_in_count: 0 }
    donations ||= { donation_total: 0 }
    payments ||= { payment_total: 0 }

    {
      'id' => event.id,
      'name' => event.name,
      'venue_name' => event.venue_name,
      'address' => event.address,
      'city' => event.city,
      'state_code' => event.state_code,
      'zip_code' => event.zip_code,
      'start_datetime' => event.start_datetime,
      'end_datetime' => event.end_datetime,
      'organizer_email' => event.organizer_email,
      'total_attendees' => tickets[:total],
      'checked_in_count' => tickets[:checked_in_count],
      'tickets_total_paid' => payments[:payment_total],
      'donations_total_paid' => donations[:donation_total],
      'total_paid' => payments[:payment_total] + donations[:donation_total]
    }
  end

  def self.ticket_metrics(event_ids)
    return {} if event_ids.blank?

    ticket_data = Ticket.where(event_id: event_ids)
                        .group(:event_id)
                        .pluck(:event_id,
                           Arel.sql('COALESCE(SUM(quantity), 0) as total'),
                           Arel.sql('COALESCE(SUM(CASE WHEN checked_in THEN 1 ELSE 0 END), 0) as checked_in_count')
                        )

    ticket_data.to_h do |event_id, total, checked_in_count|
       [event_id, {total:, checked_in_count:}]
    end
  end

  def self.donation_metrics(event_ids)
    return {} if event_ids.blank?

    donation_data = Donation.left_joins(:payments)
                            .where(event_id: event_ids)
                            .group(:event_id)
                            .pluck(:event_id, Arel.sql('COALESCE(SUM(payments.gross_amount), 0) as donation_total'))

    donation_data.to_h do |event_id, donation_total|
      [event_id, {donation_total:}]
    end
  end

  def self.payment_metrics(event_ids)
    return {} if event_ids.blank?

    # TODO: consider deleted tickets too
    payment_data = Payment.joins(:tickets)
                      .where(tickets: { event_id: event_ids })
                      .group('tickets.event_id')
                      .pluck('tickets.event_id', Arel.sql('COALESCE(SUM(payments.gross_amount), 0) as payment_total'))

    payment_data.to_h do |event_id, payment_total|
      [event_id, {payment_total:}]
    end
  end

  def self.execute(query)
    Event.connection.execute query
  end
end
