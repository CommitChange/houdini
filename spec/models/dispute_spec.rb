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

    
    # class DisputeCase < OpenStruct
    #   def initialize(args={})
    #     assign_attributes(args)
    #   end
      
    #   def mock_webhook_events
    #     unless mocked_webhook_events
    #       mocked_webhook_events ||= events.map do |i|
    #         StripeMock.mock_webhook_event(i)
    #       end

    #       StripeMockHelper.stripe_helper.upsert_stripe_object(:dispute, mock_webhook_events.last['data']['object'])
    #     end
    #   end

    #   def setup
    #     mock_webhook_events
    #     donation
    #   end

    #   def nonprofit
    #     @supporter.nonprofit
    #   end

    #   def supporter
    #     @supporter ||= create(:supporter_base)
    #   end

    #   def donation
    #     @donation ||= create(:donation_base, amount: gross_amount, supporter:supporter,  nonprofit: nonprofit,
    #         payment: build(
    #           :payment_base, gross_amount:gross_amount, fee_total: fee_total, net_amount: gross_amount + fee_total,
    #           date: date
    #           nonprofit: nonprofit,
    #           supporter: supporter,
    #           charge: build(:charge_base, amount: gross_amount, charge_id: stripe_charge_id, created_at: date, supporter: supporter, nonprofit: nonprofit)
    #         )
    #     )   
    #   end

      

    #   def transaction
    #     @transaction ||= create(:transaction_base,
    #           created: date,
    #           amount: gross_amount
    #     )
    #   end

    #   def create_dispute_event
    # end

    describe "dispute.created" do
      # include_context :dispute_created_context
      # include_context :common_specs

      def dispute_on_stripe
        StripeMockHelper.start
        event_json = StripeMock.mock_webhook_event('charge.dispute.created')
        StripeMockHelper.stripe_helper.upsert_stripe_object(:dispute, event_json['data']['object'])
        @dispute_on_stripe = event_json
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

      def setup
        dispute_on_stripe
        supporter
        nonprofit
        legacy_donation
        transaction_to_be_disputed
      end


      def transaction_to_be_disputed
        date = Time.at(1596429794) - 1.day
        fee_total = 0
        gross_amount = 80000
        stripe_charge_id = "ch_1Y7zzfBCJIIhvMWmSiNWrPAC"
        @transaction ||= build(:transaction_base,
          :receive_donation,
          created: date,
          amount: gross_amount,
          supporter: supporter,
          donation: legacy_donation
          )
      end
        
      def stripe_dispute
        event_json = create_dispute_on_stripe
        @stripe_dispute = StripeDispute.create(object: event_json['data']['object'])
      end

      def legacy_dispute
        @legacy_dispute ||= stripe_dispute.dispute
      end

      it {
        setup
        
        transaction = transaction_to_be_disputed
        
        stripe_dispute = create_stripe_dispute
        
        legacy_dispute = stripe_dispute.dispute
        
        activities = legacy_dispute.activities

        expect(activities).to include {
            kind:"DisputeCreated", 
            date: Time.at(event_json.created),
            supporter: transaction.supporter,
            nonprofit: transaction.nonprofit,
            json_data: include_json(
              status: legacy_dispute.status,
              reason: legacy_dispute.reason,
              original_id: legacy_dispute.charge.payment.id,
              original_kind: legacy_dispute.payment.kind,
              original_gross_amount: legacy_dispute.payment.gross_amount,
              original_date: charge.payment.date.to_time,
              gross_amount: legacy_dispute.gross_amount
            )

        }
      }
    end

    describe "dispute.won" do
      include_context :dispute_won_context
      include_context :common_specs

      
      let(:obj) { StripeDispute.create(object:json) }
      let(:activity) { dispute.activities.build('DisputeWon', Time.at(event_json.created)) }

      specify { expect(activity.kind).to eq 'DisputeWon' }
      specify { expect(activity.date).to eq Time.at(event_json.created) }
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
