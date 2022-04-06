# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
require 'rails_helper'

RSpec.describe Dispute, :type => :model do

  it {is_expected.to have_one(:stripe_dispute).with_primary_key(:stripe_dispute_id).with_foreign_key(:stripe_dispute_id)}

  describe '.activities' do 
    shared_context :common_specs do
      let(:activity_json) { activity.json_data}
      specify { expect(activity.supporter).to eq supporter}
      specify { expect(activity.nonprofit).to eq nonprofit}
      specify { expect(activity_json['status']).to eq dispute.status }
      specify { expect(activity_json['reason']).to eq dispute.reason }
      specify { expect(activity_json['original_id']).to eq charge.payment.id}
      specify { expect(activity_json['original_kind']).to eq charge.payment.kind}
      specify { expect(activity_json['original_gross_amount']).to eq charge.payment.gross_amount}
      specify { expect(activity_json['original_date'].to_time).to eq charge.payment.date}
      specify { expect(activity_json['gross_amount']).to eq dispute.gross_amount}
    end
    

    describe "dispute.created" do
      
      class DisputeCaseCreated
        include FactoryBot::Syntax::Methods
  
        def dispute_on_stripe
          unless @dispute_on_stripe
            StripeMockHelper.start
            event_json = StripeMock.mock_webhook_event('charge.dispute.created')
            StripeMockHelper.stripe_helper.upsert_stripe_object(:dispute, event_json['data']['object'])
          end

          @dispute_on_stripe ||= event_json
        end
  
        def legacy_donation
          fee_total = 0
          gross_amount = 80000
          stripe_charge_id = "ch_1Y7zzfBCJIIhvMWmSiNWrPAC"
          date = Time.at(1596429794) - 1.day
            @legacy_donation ||= create(:donation_base, amount: gross_amount, supporter:supporter,  nonprofit: nonprofit, payment: 
                build(
                  :payment_base, gross_amount:gross_amount, fee_total: fee_total, net_amount: gross_amount + fee_total,
                  date: date, supporter:supporter,  nonprofit: nonprofit,
                  charge: build(:charge_base, amount: gross_amount, stripe_charge_id: stripe_charge_id, created_at: date, supporter:supporter,  nonprofit: nonprofit,)
                )
            )   
        end
  
        def legacy_payment
          legacy_donation.payment
        end
  
        def nonprofit
          @supporter.nonprofit
        end
  
        def supporter
          @supporter ||= create(:supporter_base)
        end
  
        def transaction_to_be_disputed
          date = Time.at(1596429794) - 1.day
          fee_total = 0
          gross_amount = 80000
          stripe_charge_id = "ch_1Y7zzfBCJIIhvMWmSiNWrPAC"
          @transaction ||= build(:transaction_base,
            created: date,
            amount: gross_amount,
            supporter: supporter,
            legacy_donation: legacy_donation
            )
  
            @transaction.save!
          @transaction
        end
          
        def stripe_dispute
          event_json = dispute_on_stripe
          @stripe_dispute ||= StripeDispute.create(object: event_json['data']['object'])
        end
  
        def legacy_dispute
          @legacy_dispute ||= stripe_dispute.dispute
        end
  
        def setup
          dispute_on_stripe
          supporter
          nonprofit
          legacy_donation
          transaction_to_be_disputed
  
          self
        end
      end

      it {
        config = DisputeCaseCreated.new.setup
        
        transaction = config.transaction_to_be_disputed
        
        legacy_dispute = config.stripe_dispute.dispute
        
        activities = config.legacy_dispute.activities

        expect(activities).to include {
            kind:"DisputeCreated", 
            date: Time.at(config.event_json.created),
            supporter: transaction.supporter,
            nonprofit: transaction.nonprofit,
            json_data: include_json(
              status: legacy_dispute.status,
              reason: legacy_dispute.reason,
              original_id: legacy_dispute.charge.payment.id,
              original_kind: legacy_dispute.payment.kind,
              original_gross_amount: legacy_dispute.payment.gross_amount,
              original_date: config.charge.payment.date.to_time,
              gross_amount: legacy_dispute.gross_amount
            )

        }
      }

      it {
        config = DisputeCaseCreated.new.setup
        expect(config.stripe_dispute).to have_attributes(
          'status'=> 'needs_response',
          "reason" => 'duplicate',
          "balance_transactions" => [],
          "net_change" => 0,
          "amount" => 80000,
          "stripe_charge_id" => "ch_1Y7zzfBCJIIhvMWmSiNWrPAC",
          "stripe_dispute_id" => "dp_05RsQX2eZvKYlo2C0FRTGSSA",
          "started_at" => Time.at(1596429794),
        )
      }

      it {
        config = DisputeCaseCreated.new.setup
        expect(config.stripe_dispute.dispute).to be_persisted
      }

      it {
        config = DisputeCaseCreated.new.setup
        expect(config.stripe_dispute.dispute.attributes).to include( 
        'status'=> 'needs_response',
        "reason" => 'duplicate',
        "gross_amount" => 80000,
        "stripe_dispute_id" => "dp_05RsQX2eZvKYlo2C0FRTGSSA",
        "started_at" => Time.at(1596429794)
        )
      }

      it {
        config = DisputeCaseCreated.new.setup
        config.transaction_to_be_disputed.reload
        expect(config.transaction_to_be_disputed.payments.count).to eq 1
      }
    end

    describe "dispute.won" do

      class DisputeCaseWon
        include FactoryBot::Syntax::Methods
  
        def dispute_on_stripe
          StripeMockHelper.start
          event_json = StripeMock.mock_webhook_event('charge.dispute.closed-won')
          StripeMockHelper.stripe_helper.upsert_stripe_object(:dispute, event_json['data']['object'])
          @dispute_on_stripe ||= event_json
        end
  
        def legacy_donation
          fee_total = 0
          gross_amount = 80000
          stripe_charge_id = "ch_1Y7vFYBCJIIhvMWmsdRJWSw5"
          date = Time.new(2019, 8, 5) - 1.day
            @legacy_donation ||= create(:donation_base, amount: gross_amount, supporter:supporter,  nonprofit: nonprofit, payment: 
                build(
                  :payment_base, gross_amount:gross_amount, fee_total: fee_total, net_amount: gross_amount + fee_total,
                  date: date, supporter:supporter,  nonprofit: nonprofit,
                  charge: build(:charge_base, amount: gross_amount, stripe_charge_id: stripe_charge_id, created_at: date, supporter:supporter,  nonprofit: nonprofit,)
                )
            )   
        end
  
        def legacy_payment
          legacy_donation.payment
        end
  
        def nonprofit
          @supporter.nonprofit
        end
  
        def supporter
          @supporter ||= create(:supporter_base)
        end
  
        def transaction_to_be_disputed
          date = Time.new(2019, 8, 5) - 1.day
          fee_total = 0
          gross_amount = 80000
          stripe_charge_id = "ch_1Y7vFYBCJIIhvMWmsdRJWSw5"
          @transaction ||= build(:transaction_base,
            created: date,
            amount: gross_amount,
            supporter: supporter,
            legacy_donation: legacy_donation
            )
  
            @transaction.save!
          @transaction
        end
          
        def stripe_dispute
          event_json = dispute_on_stripe
          @stripe_dispute ||= StripeDispute.create(object: event_json['data']['object'])
        end
  
        def legacy_dispute
          @legacy_dispute ||= stripe_dispute.dispute
        end

        def withdrawal_dispute_transaction
          legacy_dispute.dispute_transactions.order("date").first
        end

        def reinstated_dispute_transaction
          legacy_dispute.dispute_transactions.order("date").second
        end

        def withdrawal_dispute_legacy_payment
          legacy_dispute.dispute_transactions.order("date").first.payment
        end

        def reinstated_dispute_legacy_payment
          legacy_dispute.dispute_transactions.order("date").second.payment
        end

        def transaction_payment_charge
          transaction_to_be_disputed.reload
          transaction_to_be_disputed.ordered_payments.last
        end

        def transaction_payment_withdrawal
          transaction_to_be_disputed.reload
          case transaction_to_be_disputed.ordered_payments.count
          when 2
            transaction_to_be_disputed.ordered_payments.first
          when 3
            transaction_to_be_disputed.ordered_payments.second
          else
            nil
          end
        end

        def transaction_payment_reinstated
          transaction_to_be_disputed.reload
          case transaction_to_be_disputed.ordered_payments.count
          when 3
             transaction_to_be_disputed.ordered_payments.first
          else
            nil
          end
        end
  
        def setup
          dispute_on_stripe
          supporter
          nonprofit
          legacy_donation
          transaction_to_be_disputed
          stripe_dispute
          self
        end
      end

      it {
        config = DisputeCaseWon.new.setup
        
        transaction = config.transaction_to_be_disputed
        
        legacy_dispute = config.stripe_dispute.dispute
        
        activities = config.legacy_dispute.activities

        expect(activities).to include {
            kind:"DisputeWon", 
            date: Time.at(config.event_json.created),
            supporter: transaction.supporter,
            nonprofit: transaction.nonprofit,
            json_data: include_json(
              status: legacy_dispute.status,
              reason: legacy_dispute.reason,
              original_id: legacy_dispute.charge.payment.id,
              original_kind: legacy_dispute.payment.kind,
              original_gross_amount: legacy_dispute.payment.gross_amount,
              original_date: config.charge.payment.date.to_time,
              gross_amount: legacy_dispute.gross_amount
            )

        }
      }

      it {
        config = DisputeCaseWon.new.setup
        expect(config.stripe_dispute).to have_attributes(
          'status'=> 'won',
          "reason" => 'credit_not_processed',
          "balance_transactions" => an_instance_of(Array).and(have_attributes(count:2)),
          "net_change" => 0,
          "amount" => 80000,
          "stripe_charge_id" => "ch_1Y7vFYBCJIIhvMWmsdRJWSw5",
          "stripe_dispute_id" => "dp_15RsQX2eZvKYlo2C0ERTYUIA",
          "started_at" => Time.at(1565008160),
        )
      }

      it {
        config = DisputeCaseWon.new.setup
        expect(config.legacy_dispute).to be_persisted
      }

      it {
        config = DisputeCaseWon.new.setup
        expect(config.legacy_dispute).to have_attributes( 
        'status'=> 'won',
        "reason" => 'credit_not_processed',
        "gross_amount" => 80000,
        "stripe_dispute_id" => "dp_15RsQX2eZvKYlo2C0ERTYUIA",
        "started_at" => Time.at(1565008160)
        )
      }

      it {
        config = DisputeCaseWon.new.setup
        config.transaction_to_be_disputed.reload
        expect(config.transaction_to_be_disputed.payments.count).to eq 3
      }

      it {
        config = DisputeCaseWon.new.setup
        withdrawal_dispute_transaction = config.withdrawal_dispute_transaction
        expect(withdrawal_dispute_transaction).to be_persisted
      }

      it {
        config = DisputeCaseWon.new.setup
        withdrawal_dispute_transaction = config.withdrawal_dispute_transaction
        expect(withdrawal_dispute_transaction).to have_attributes(
          gross_amount: -80000,
          fee_total: -1500,
          stripe_transaction_id: 'txn_1Y75JVBCJIIhvMWmsnGK1JLD',
          date: DateTime.new(2019,8,5,12,29,20),
          disbursed: false
        )
      }

      it {
        config = DisputeCaseWon.new.setup
        withdrawal_payment = config.withdrawal_dispute_legacy_payment
        expect(withdrawal_payment).to be_persisted
      }


      it {
        config = DisputeCaseWon.new.setup
        withdrawal_payment = config.withdrawal_dispute_legacy_payment
        expect(withdrawal_payment).to have_attributes(
          gross_amount: -80000,
          fee_total: -1500,
          net_amount: -81500,
          kind: "Dispute",
          nonprofit: config.nonprofit,
          date: DateTime.new(2019,8,5,12,29,20)
        )
      }

      it {
        config = DisputeCaseWon.new.setup
        reinstated_dispute_transaction = config.reinstated_dispute_transaction
        expect(reinstated_dispute_transaction).to be_persisted 
      }

      it {
        config = DisputeCaseWon.new.setup
        reinstated_dispute_transaction = config.reinstated_dispute_transaction
        expect(reinstated_dispute_transaction).to have_attributes(
          gross_amount: 80000,
          fee_total: 1500,
          stripe_transaction_id: 'txn_1Y71X0BCJIIhvMWmMmtTY4m1',
          date: DateTime.new(2019,10,29,20,43,10),
          disbursed: false
        )
      }

      it {
        config = DisputeCaseWon.new.setup
        reinstated_payment = config.reinstated_dispute_legacy_payment
        expect(reinstated_payment).to have_attributes(
          gross_amount: 80000,
          fee_total: 1500,
          net_amount: 81500,
          kind: "DisputeReversed",
          nonprofit: config.nonprofit,
          date: DateTime.new(2019,10,29,20,43,10)
        )
      }
      
      it {
        config = DisputeCaseWon.new.setup
        config.transaction_to_be_disputed.reload
        expect(config.transaction_to_be_disputed.payments.count).to eq 3
      }


      it {
        config = DisputeCaseWon.new.setup
        expect(config.transaction_payment_withdrawal.paymentable).to be_a StripeTransactionDispute
      }

      it {
        config = DisputeCaseWon.new.setup
        expect(config.transaction_payment_withdrawal).to have_attributes(
          legacy_payment: config.withdrawal_dispute_legacy_payment,
          gross_amount: -80000,
          fee_total: -1500,
          net_amount: -81500
        )
      }


      it {
        config = DisputeCaseWon.new.setup
        expect(config.transaction_payment_reinstated.paymentable).to be_a StripeTransactionDisputeReversal
      }

      it {
        config = DisputeCaseWon.new.setup
        expect(config.transaction_payment_reinstated).to have_attributes(
          legacy_payment: config.reinstated_dispute_legacy_payment,
          gross_amount: 80000,
          fee_total: 1500,
          net_amount: 81500
        )
      }


  
      
    #   # let(:obj) { StripeDispute.create(object:json) }
    #   # let(:activity) { dispute.activities.build('DisputeWon', Time.at(event_json.created)) }

    #   # specify { expect(activity.kind).to eq 'DisputeWon' }
    #   # specify { expect(activity.date).to eq Time.at(event_json.created) }
    end

    describe "dispute.lost" do
      include_context :common_specs
      include_context :dispute_lost_context
      
      let(:obj) { StripeDispute.create(object:json) }
      let(:activity) { obj.dispute.activities.build('DisputeLost', Time.at(event_json.created))}

      specify { expect(activity.kind).to eq 'DisputeLost'}
      specify { expect(activity_json['gross_amount']).to eq dispute.gross_amount}
      specify { expect(activity.date).to eq Time.at(event_json.created)}
    end
  end
end
