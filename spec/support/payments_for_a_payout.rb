# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
shared_context 'payments for a payout' do

  let(:today) { Time.new(2020,5,5, 1) }
  let(:yesterday) {Time.new(2020,5,4, 1)}
  let(:two_days_ago) {Time.new(2020,5,3, 1)}
  
  # let(:all_payments) {
  #   payment_with_charge_to_output
  #   partial_refunded_payment
  #   refunded_payment
  #   disputed_payment
  #   late_payment
  #   paid_out_payment
  #   paid_out_refund
  #   paid_out_dispute
  #   other_np_payment
  # }
  let(:eb_two_days_ago) {EntityBuilder.new(two_days_ago, nonprofit)}
  let(:entities_two_days_ago){eb_two_days_ago.entities}
  let(:payments_two_days_ago){eb_two_days_ago.payments}
  let(:available_payments_two_days_ago) { eb_two_days_ago.available_payments}

  let(:eb_yesterday) {EntityBuilder.new(yesterday, nonprofit) }
  let(:entities_yesterday) {eb_yesterday.entities}
  let(:payments_yesterday){eb_yesterday.payments}
  let(:available_payments_yesterday) { eb_yesterday.available_payments}

  let(:eb_today) {EntityBuilder.new(today, nonprofit) }
  let(:entities_today) {eb_today.entities}
  let(:payments_today) {eb_today.payments}
  let(:available_payments_today) { eb_today.available_payments}

  class EntityBuilder
    include FactoryBot::Syntax::Methods
    include FactoryBotExtensions
    attr_accessor :entities
    def initialize(time, nonprofit, other_nonprofit=nil)
      @time = time

      @nonprofit = nonprofit
      @other_nonprofit = other_nonprofit
      @entities = build_entities
    end

    def payments
      entities.map do |k,v|
        output = nil
        if (v.is_a? Charge)
          output = [v.payment]
        elsif (v.is_a? Refund)
          output = [v.payment, v.charge.payment]
        elsif (v.is_a? Dispute)
          output = v.dispute_transactions.map{|dt| dt.payment}.concat([v.charge.payment])
        end
        output
      end.flatten.uniq
    end

    def available_payments
      entities.map do |k,v|
        output = []
        if (v.is_a?(Charge) && v.status == 'available')
          output  << v.payment
        elsif (v.is_a? Refund)
          if !v.disbursed
            output << v.payment
          end
          if (v.charge.status == 'available')
            output << v.charge.payment
          end
        elsif (v.is_a? Dispute)
          if (v.charge.status == 'available')
            output << v.charge.payment
          end
          output = output.concat(v.dispute_transactions.select{|i| !i.disbursed}.map{|dt|dt.payment})
        end
        output
      end.flatten.uniq
    end

    private
    def build_entities
      output = {}
      Timecop.freeze(@time) do
        output[:charge_available] = charge_available
        output[:charge_paid] = charge_paid
        output[:charge_pending] = charge_pending
        output[:refund_disbursed] = refund_disbursed
        output[:refund] = refund
        output[:legacy_dispute_paid] = legacy_dispute_paid
        output[:legacy_dispute_won] = legacy_dispute_won
        output[:legacy_dispute_lost] = legacy_dispute_lost
        output[:dispute_lost] = dispute_lost
        output[:dispute_won] = dispute_won
        output[:dispute_paid] = dispute_paid
        output[:dispute_under_review] = dispute_under_review
        output[:dispute_needs_response] = dispute_needs_response
        # output[:partial_dispute_lost] = partial_dispute_lost
        # output[:partial_dispute_won] = partial_dispute_won
        # output[:partial_refund] = partial_refund
      end
      output
    end

    private
    
    #net 100
    def charge_available
      charge_create(gross_amount:100, status: 'available')
    end

    # net 0
    def charge_paid
      charge_create(gross_amount:200, status: 'paid')
    end

    # 400 pending
    def charge_pending 
      charge_create(gross_amount:400, status: 'pending')
    end

    # net 0
    def refund_disbursed
      refund_create({gross_amount:800, original_charge_args: {status: 'paid'}, disbursed: true})
    end

    # net 0
    def refund
      refund_create({gross_amount:1600, original_charge_args:{status: 'available'}})
    end

    # net 0
    def legacy_dispute_paid
      d= dispute_create(gross_amount:3200, status: :lost, original_charge_args: {status: 'paid'})
      d.dispute_transactions.create(**dispute_transaction_args_create(-3200, 0), disbursed: true)
      d
    end

    # net 6400
    def legacy_dispute_won
      d = dispute_create(gross_amount:6400, status: :won)
    end

    # net 0
    def legacy_dispute_lost
      d = dispute_create(gross_amount:25600, status: :lost)
      d.dispute_transactions.create(**dispute_transaction_args_create(-25600, 0))
      d
    end
    
    # net -1500
    def dispute_lost
      d = dispute_create(gross_amount:12800, status: :lost)
      d.dispute_transactions.create(**dispute_transaction_args_create(-12800, -1500))
      d
    end

    # net 51200
    def dispute_won
      d = dispute_create({gross_amount: 51200, status: :won})
      d.dispute_transactions.create(**dispute_transaction_args_create(-51200, -1500))
      d.dispute_transactions.create(**dispute_transaction_args_create(51200, 1500))
      d
    end

    # net 0
    def dispute_paid
      d = dispute_create(gross_amount:102800, status: :lost, original_charge_args: {status: :paid})
      d.dispute_transactions.create(disbursed: true, **dispute_transaction_args_create(-102800, -1500))
      d
    end

    # net -1500
    def dispute_under_review
      d = dispute_create(gross_amount:205600, status: :under_review)
      d.dispute_transactions.create(**dispute_transaction_args_create(-205600, -1500))
      d
    end

    # net -1500
    def dispute_needs_response
      d = dispute_create(gross_amount:512000, status: :needs_response)
      d.dispute_transactions.create(**dispute_transaction_args_create(-512000, -1500))
      d
    end
  

    def refund_create(**args)
      fee_total = args[:fee_total] || 0

      gross_amount = args[:gross_amount]
      fee_total = args[:fee_total] || 0
      
      temp_charge_args = {gross_amount:gross_amount, fee_total: fee_total }
      temp_charge_args = temp_charge_args.merge(args[:original_charge_args]) if args[:original_charge_args]


      orig_charge = charge_create(status: 'available', **temp_charge_args)

      force_create(:refund, amount: args[:gross_amount], charge: orig_charge, payment: payment_create( gross_amount:-1 * gross_amount, fee_total: fee_total || 0, net_amount:  (-1 * gross_amount) - fee_total), **args.except(:gross_amount, :original_charge_args))
    end

    def dispute_create(**args)
      gross_amount = args[:gross_amount]
      temp_charge_args = {gross_amount:gross_amount }
      temp_charge_args = temp_charge_args.merge(args[:original_charge_args]) if args[:original_charge_args]
      orig_charge = charge_create(status: 'available', **temp_charge_args)
      force_create(:dispute, :autocreate_dispute, gross_amount: gross_amount, charge: orig_charge, **args.except(:original_charge_args))
    end

    def dispute_transaction_args_create(gross_amount, fee_total)
      {gross_amount: gross_amount, fee_total: fee_total, 
        payment: payment_create(gross_amount:gross_amount, fee_total: fee_total, net_amount: gross_amount + fee_total,
          nonprofit: @nonprofit )}
    end

    def charge_create( **args)
      gross_amount = args[:gross_amount]
      fee_total = args[:fee_total] || 0
      other_args = args.except(:gross_amount, :fee_total)
      force_create(:charge, nonprofit:@nonprofit, amount: gross_amount, 
        payment: payment_create(gross_amount: gross_amount, fee_total: fee_total, net_amount: gross_amount + fee_total), **other_args)
    end

    def payment_create(**args)
      force_create(:payment, nonprofit:@nonprofit, date: @time, **args)
    end


  end
end