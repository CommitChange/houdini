# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
require 'rails_helper'

RSpec.describe StripeEvent, :type => :model do

  

   
    



  around(:each) do |example|
    StripeMock.start
    Timecop.freeze(Date.new(2021, 5, 4)) do
      example.run
    end
    StripeMock.stop
  end

  describe "stripe_account.updated" do 
    let(:nonprofit_verification_process_status) do
      create(:nonprofit_verification_process_status,
      stripe_account_id: 'acct_1G8Y94CcxDUSisy4',
      started_at: DateTime.now - 1.minutes,
      email_to_send_guid: fake_send_guid
    )
    end

    let(:fake_send_guid) {'FAKE_GUID'}
    let(:event_object_for_pending) {
      create(:stripe_event,
        event_id:"test_evt_1", 
        event_time: DateTime.now - 1.minutes, 
        object_id: 'acct_1G8Y94CcxDUSisy4')
    }

    let(:later_event_object) {
      create(:stripe_event,
        event_id:"test_evt_new", 
        event_time: DateTime.now + 1.minutes, 
        object_id: 'acct_1G8Y94CcxDUSisy4')
    }

    let(:previous_event_object) {
      create(:stripe_event,
        event_id:"test_evt_old", 
        event_time: DateTime.now - 1.minutes, 
        object_id: 'acct_1G8Y94CcxDUSisy4')
    }

    it 'skips processing already processed events' do
      event_object_for_pending
      StripeEvent.handle(StripeMock.mock_webhook_event('account.updated.with-pending'))
      expect(StripeAccount.count).to eq 0
    end

    it 'skips processing weve already processed a newer event for object' do
      later_event_object
      StripeEvent.handle(StripeMock.mock_webhook_event('account.updated.with-pending'))
      expect(StripeAccount.count).to eq 0
    end

    describe 'new StripeAccount' do
      describe 'handles unverified' do
        let(:event_json) { StripeMock.mock_webhook_event('account.updated.with-unverified')}

        let(:last_event) { StripeEvent.last}
        let(:last_account) { StripeAccount.last}
        
        describe 'when in verification process' do
          before(:each) do
            nonprofit_verification_process_status
            previous_event_object
            sam = double(StripeAccountMailer)
            expect(sam).to receive(:conditionally_send_not_completed)
            expect(StripeAccountMailer).to receive(:delay).with(run_at: DateTime.now + 5.minutes).and_return(sam)
            StripeEvent.handle(event_json)
          end

          it 'saved the event' do
            expect(last_event.event_id).to eq 'test_evt_1'
            expect(last_event.object_id).to eq 'acct_1G8Y94CcxDUSisy4'
            expect(last_event.event_time).to eq Time.now
          end

          it 'saves StripeAccount' do 
            expect(last_account.verification_status).to be :unverified
          end

          it 'updates the NonprofitVerificationProcessStatus' do
            nonprofit_verification_process_status.reload
            expect(nonprofit_verification_process_status.email_to_send_guid).to_not eq fake_send_guid
          end
        end

        describe 'when not in verification process' do
          before(:each) do
            previous_event_object
            expect(StripeAccountMailer).to_not receive(:delay)
            StripeEvent.handle(event_json)
          end

          it 'saved the event' do
            expect(last_event.event_id).to eq 'test_evt_1'
            expect(last_event.object_id).to eq 'acct_1G8Y94CcxDUSisy4'
            expect(last_event.event_time).to eq Time.now
          end

          it 'saves StripeAccount' do 
            expect(last_account.verification_status).to be :unverified
          end

          it 'doesnt add a NonprofitVerificationProcessStatus' do
            expect(NonprofitVerificationProcessStatus.count).to eq 0
          end
        end
      end

      describe 'handles temporarily_verified' do
        let(:event_json) { StripeMock.mock_webhook_event('account.updated.with-temporarily_verified')}

        let(:last_event) { StripeEvent.last}
        let(:last_account) { StripeAccount.last}
        
        describe 'when in verification process' do
          before(:each) do
            nonprofit_verification_process_status
            previous_event_object
            sam = double(StripeAccountMailer)
            expect(sam).to receive(:conditionally_send_verified)
            expect(StripeAccountMailer).to receive(:delay).and_return(sam)
            StripeEvent.handle(event_json)
          end

          it 'saved the event' do
            expect(last_event.event_id).to eq 'test_evt_1'
            expect(last_event.object_id).to eq 'acct_1G8Y94CcxDUSisy4'
            expect(last_event.event_time).to eq Time.now
          end

          it 'saves StripeAccount' do 
            expect(last_account.verification_status).to be :temporarily_verified
          end

          it 'updates the NonprofitVerificationProcessStatus' do
            expect {nonprofit_verification_process_status.reload}.to raise_error ActiveRecord::RecordNotFound
          end
        end

        describe 'when not in verification process' do
          before(:each) do
            previous_event_object
            expect(StripeAccountMailer).to_not receive(:delay)
            StripeEvent.handle(event_json)
          end

          it 'saved the event' do
            expect(last_event.event_id).to eq 'test_evt_1'
            expect(last_event.object_id).to eq 'acct_1G8Y94CcxDUSisy4'
            expect(last_event.event_time).to eq Time.now
          end

          it 'saves StripeAccount' do 
            expect(last_account.verification_status).to eq :temporarily_verified
          end

          it 'doesnt add a NonprofitVerificationProcessStatus' do
            expect(NonprofitVerificationProcessStatus.count).to eq 0
          end
        end
      end

      describe 'handles verified' do
        let(:event_json) { StripeMock.mock_webhook_event('account.updated.with-verified')}
        let(:last_event) { StripeEvent.last}
        let(:last_account) { StripeAccount.last}
        
        describe 'when in verification process' do
          before(:each) do
            nonprofit_verification_process_status
            previous_event_object
            sam = double(StripeAccountMailer)
            expect(sam).to receive(:conditionally_send_verified)
            expect(StripeAccountMailer).to receive(:delay).and_return(sam)
            StripeEvent.handle(event_json)
          end
          
          it 'saved the event' do
            expect(last_event.event_id).to eq 'test_evt_1'
            expect(last_event.object_id).to eq 'acct_1G8Y94CcxDUSisy4'
            expect(last_event.event_time).to eq Time.now
          end

          it 'saves StripeAccount' do 
            expect(last_account.verification_status).to be :verified
          end

          it 'deleted the NonprofitVerificationProcessStatus' do
            expect {nonprofit_verification_process_status.reload}.to raise_error ActiveRecord::RecordNotFound
          end
        end

        describe 'when not in verification process' do
          before(:each) do
            previous_event_object
            expect(StripeAccountMailer).to_not receive(:delay)
            StripeEvent.handle(event_json)
          end
          
          it 'saved the event' do
            expect(last_event.event_id).to eq 'test_evt_1'
            expect(last_event.object_id).to eq 'acct_1G8Y94CcxDUSisy4'
            expect(last_event.event_time).to eq Time.now
          end

          it 'saves StripeAccount' do 
            expect(last_account.verification_status).to be :verified
          end

          it 'doesnt add a NonprofitVerificationProcessStatus' do
            expect(NonprofitVerificationProcessStatus.count).to eq 0
          end
        end
      end
    end


    describe 'old StripeAccount' do 
      describe 'handles unverified' do
        let(:event_json) { StripeMock.mock_webhook_event('account.updated.with-unverified')}
        let(:last_event) { StripeEvent.last}
        let(:last_account) { create(:stripe_account, stripe_account_id:'acct_1G8Y94CcxDUSisy4', currently_due: JSON::generate(['something']))}

        describe 'when in verification process' do
          before(:each) do
            nonprofit_verification_process_status
            last_account
            previous_event_object
            sam = double(StripeAccountMailer)
            expect(sam).to receive(:conditionally_send_not_completed)
            expect(StripeAccountMailer).to receive(:delay).with(run_at: DateTime.now + 5.minutes).and_return(sam)
            StripeEvent.handle(event_json)
          end

          it 'saved the event' do
            expect(last_event.event_id).to eq 'test_evt_1'
            expect(last_event.object_id).to eq 'acct_1G8Y94CcxDUSisy4'
            expect(last_event.event_time).to eq Time.now
          end

          it 'saves StripeAccount' do 
            last_account.reload
            expect(last_account.verification_status).to be :unverified
          end

          it 'updates the NonprofitVerificationProcessStatus' do
            
            nonprofit_verification_process_status.reload
            expect(nonprofit_verification_process_status.email_to_send_guid).to_not eq fake_send_guid
          end
        end

        describe 'when not in verification process' do
          before(:each) do
            last_account
            last_account.currently_due = JSON::generate(['something'])
            last_account.save!
            previous_event_object
            # byebug
            expect(StripeAccountMailer).to_not receive(:delay)
            StripeEvent.handle(event_json)
          end

          it 'saved the event' do
            expect(last_event.event_id).to eq 'test_evt_1'
            expect(last_event.object_id).to eq 'acct_1G8Y94CcxDUSisy4'
            expect(last_event.event_time).to eq Time.now
          end

          it 'saves StripeAccount' do 
            last_account.reload
            expect(last_account.verification_status).to be :unverified
          end

          it 'doesnt add a NonprofitVerificationProcessStatus' do
            expect(NonprofitVerificationProcessStatus.count).to eq 0
          end
        end
      end

      describe 'handles from pending to unverified' do
        let(:event_json) { StripeMock.mock_webhook_event('account.updated.with-unverified')}
        let(:last_event) { StripeEvent.last}
        let(:last_account) { create(:stripe_account, stripe_account_id:'acct_1G8Y94CcxDUSisy4')}

        describe 'when in verification process' do
          before(:each) do
            nonprofit_verification_process_status
            last_account
            last_account.pending_verification = JSON::generate(['exciting'])
            last_account.save!
            previous_event_object
            sam = double(StripeAccountMailer)
            expect(sam).to receive(:conditionally_send_more_info_needed)
            expect(StripeAccountMailer).to receive(:delay).with(run_at: DateTime.now + 5.minutes).and_return(sam)
            expect(last_account.verification_status).to eq :pending
            StripeEvent.handle(event_json)
          end

      
      
          it 'saved the event' do
            expect(last_event.event_id).to eq 'test_evt_1'
            expect(last_event.object_id).to eq 'acct_1G8Y94CcxDUSisy4'
            expect(last_event.event_time).to eq Time.now
          end

          it 'saves StripeAccount' do 
            last_account.reload
            expect(last_account.verification_status).to be :unverified
          end

          it 'updates the NonprofitVerificationProcessStatus' do
            
            nonprofit_verification_process_status.reload
            expect(nonprofit_verification_process_status.email_to_send_guid).to_not eq fake_send_guid
          end
        end

        describe 'when not in verification process' do
          before(:each) do
            last_account
            last_account.pending_verification = JSON::generate(['exciting'])
            last_account.save!
            previous_event_object
            expect(StripeAccountMailer).to_not receive(:delay)
            expect(last_account.verification_status).to eq :pending
            StripeEvent.handle(event_json)
          end

      
      
          it 'saved the event' do
            expect(last_event.event_id).to eq 'test_evt_1'
            expect(last_event.object_id).to eq 'acct_1G8Y94CcxDUSisy4'
            expect(last_event.event_time).to eq Time.now
          end

          it 'saves StripeAccount' do 
            last_account.reload
            expect(last_account.verification_status).to be :unverified
          end

          it 'doesnt add a NonprofitVerificationProcessStatus' do
            expect(NonprofitVerificationProcessStatus.count).to eq 0
          end
        end
      end

      describe 'handles temporarily_verified' do
        let(:event_json) { StripeMock.mock_webhook_event('account.updated.with-temporarily_verified')}

        let(:last_event) { StripeEvent.last}
        let(:last_account) { create(:stripe_account, stripe_account_id:'acct_1G8Y94CcxDUSisy4')}
        
        describe 'when in verification process' do
          before(:each) do
            nonprofit_verification_process_status
            last_account
            previous_event_object
            sam = double(StripeAccountMailer)
            expect(sam).to receive(:conditionally_send_verified)
            expect(StripeAccountMailer).to receive(:delay).and_return(sam)
            StripeEvent.handle(event_json)
            last_account.reload
          end

          it 'saved the event' do
            expect(last_event.event_id).to eq 'test_evt_1'
            expect(last_event.object_id).to eq 'acct_1G8Y94CcxDUSisy4'
            expect(last_event.event_time).to eq Time.now
          end

          it 'saves StripeAccount' do 
            expect(last_account.verification_status).to eq :temporarily_verified
          end

          it 'updates the NonprofitVerificationProcessStatus' do
            expect {nonprofit_verification_process_status.reload}.to raise_error ActiveRecord::RecordNotFound
          end
        end
        
        describe 'when not in verification process' do
          before(:each) do
            previous_event_object
            last_account
            expect(StripeAccountMailer).to_not receive(:delay)
            StripeEvent.handle(event_json)
            last_account.reload
          end

          it 'saved the event' do
            expect(last_event.event_id).to eq 'test_evt_1'
            expect(last_event.object_id).to eq 'acct_1G8Y94CcxDUSisy4'
            expect(last_event.event_time).to eq Time.now
          end

          it 'saves StripeAccount' do 
            expect(last_account.verification_status).to eq :temporarily_verified
          end

          it 'doesnt add a NonprofitVerificationProcessStatus' do
            expect(NonprofitVerificationProcessStatus.count).to eq 0
          end
        end
      end

      describe 'handles verified' do
        let(:event_json) { StripeMock.mock_webhook_event('account.updated.with-verified')}
        let(:last_event) { StripeEvent.last}
        let(:last_account) { create(:stripe_account, stripe_account_id:'acct_1G8Y94CcxDUSisy4', currently_due: ['something'])}
        describe 'when in verification process' do
          before(:each) do
            nonprofit_verification_process_status
            last_account
            previous_event_object
            sam = double(StripeAccountMailer)
            expect(sam).to receive(:conditionally_send_verified)
            expect(StripeAccountMailer).to receive(:delay).and_return(sam)
            StripeEvent.handle(event_json)
            
          end
          
          it 'saved the event' do
            expect(last_event.event_id).to eq 'test_evt_1'
            expect(last_event.object_id).to eq 'acct_1G8Y94CcxDUSisy4'
            expect(last_event.event_time).to eq Time.now
          end

          it 'saves StripeAccount' do 
            expect(last_account.verification_status).to be :verified
          end

          it 'deleted the NonprofitVerificationProcessStatus' do
            expect {nonprofit_verification_process_status.reload}.to raise_error ActiveRecord::RecordNotFound
          end
        end

        describe 'when not in verification process' do
          before(:each) do
            last_account
            previous_event_object
            expect(StripeAccountMailer).to_not receive(:delay)
            StripeEvent.handle(event_json)
          end
          
          it 'saved the event' do
            expect(last_event.event_id).to eq 'test_evt_1'
            expect(last_event.object_id).to eq 'acct_1G8Y94CcxDUSisy4'
            expect(last_event.event_time).to eq Time.now
          end

          it 'saves StripeAccount' do 
            expect(last_account.verification_status).to be :verified
          end

          it 'doesnt add a NonprofitVerificationProcessStatus' do
            expect(NonprofitVerificationProcessStatus.count).to eq 0
          end
        end
      end

      describe 'handles pending' do
        let(:event_json) { StripeMock.mock_webhook_event('account.updated.with-pending')}
        let(:last_event) { StripeEvent.last}
        let(:last_account) { create(:stripe_account, stripe_account_id:'acct_1G8Y94CcxDUSisy4', currently_due: ['something'])}
        describe 'when in verification process' do
          before(:each) do
            nonprofit_verification_process_status
            last_account
            previous_event_object
            sam = double(StripeAccountMailer)
            expect(sam).to receive(:conditionally_send_not_completed)
            expect(StripeAccountMailer).to receive(:delay).and_return(sam)
            StripeEvent.handle(event_json)
            
          end
          
          it 'saved the event' do
            expect(last_event.event_id).to eq 'test_evt_1'
            expect(last_event.object_id).to eq 'acct_1G8Y94CcxDUSisy4'
            expect(last_event.event_time).to eq Time.now
          end

          it 'saves StripeAccount' do
            last_account.reload
            expect(last_account.verification_status).to be :pending
          end

          it 'updates the NonprofitVerificationProcessStatus' do
            
            nonprofit_verification_process_status.reload
            expect(nonprofit_verification_process_status.email_to_send_guid).to_not eq fake_send_guid
          end
        end
        
        describe 'when not in verification process' do
          before(:each) do
            last_account
            previous_event_object
            expect(StripeAccountMailer).to_not receive(:delay)
            StripeEvent.handle(event_json)
          end
          
          it 'saved the event' do
            expect(last_event.event_id).to eq 'test_evt_1'
            expect(last_event.object_id).to eq 'acct_1G8Y94CcxDUSisy4'
            expect(last_event.event_time).to eq Time.now
          end

          it 'saves StripeAccount' do
            last_account.reload
            expect(last_account.verification_status).to be :pending
          end

          it 'doesnt add a NonprofitVerificationProcessStatus' do
            expect(NonprofitVerificationProcessStatus.count).to eq 0
          end
        end
      end

      describe 'handles verified to unverified' do
        let(:deadline) { Time.utc(2020, 2, 28, 22, 27, 35)}
        let(:event_json) { StripeMock.mock_webhook_event('account.updated.with-unverified-from-verified')}
        let(:last_event) { StripeEvent.last}
        let(:last_account) { create(:stripe_account, stripe_account_id:'acct_1G8Y94CcxDUSisy4')}

        describe 'when not in verification process' do
          before(:each) do
            last_account
            previous_event_object
            sam = double(StripeAccountMailer)
            expect(sam).to receive(:conditionally_send_no_longer_verified).with(last_account)
            expect(StripeAccountMailer).to receive(:delay).and_return(sam)
            expect(last_account.verification_status).to eq :verified
            StripeEvent.handle(event_json)
          end

          it 'saved the event' do
            expect(last_event.event_id).to eq 'test_evt_1'
            expect(last_event.object_id).to eq 'acct_1G8Y94CcxDUSisy4'
            expect(last_event.event_time).to eq Time.now
          end

          it 'saves StripeAccount' do 
            last_account.reload
            expect(last_account.verification_status).to eq :unverified
          end

          it 'doesnt add a NonprofitVerificationProcessStatus' do
            expect(NonprofitVerificationProcessStatus.count).to eq 0
          end
        end
      end
    end
  end

  describe 'charge.dispute.*' do
    
    let(:event_object_for_dispute) {
      create(:stripe_event,
        event_id:"test_evt_1", 
        event_time: DateTime.now - 1.minutes, 
        object_id: 'du_1Y7pRWBCJIIhvMWmv0ZPR9Ef')
    }

    let(:later_event_object) {
      create(:stripe_event,
        event_id:"test_evt_new", 
        event_time: DateTime.now + 1.minutes, 
        object_id: 'du_1Y7pRWBCJIIhvMWmv0ZPR9Ef')
    }

    let(:previous_event_object) {
      create(:stripe_event,
        event_id:"test_evt_old", 
        event_time: DateTime.now - 1.minutes, 
        object_id: 'du_1Y7pRWBCJIIhvMWmv0ZPR9Ef')
    }
    it 'skips processing already processed events' do
      event_object_for_dispute
      StripeEvent.handle(StripeMock.mock_webhook_event('charge.dispute.created'))
      expect(StripeDispute.count).to eq 0
    end

    it 'skips processing weve already processed a newer event for object' do
      later_event_object
      StripeEvent.handle(StripeMock.mock_webhook_event('charge.dispute.created'))
      expect(StripeDispute.count).to eq 0
    end

    describe 'created' do
      let(:event_json) { StripeMock.mock_webhook_event('charge.dispute.created')}

      let(:last_event) { StripeEvent.last}
      let(:last_dispute) { StripeDispute.last}
      
      before(:each) do
        previous_event_object
        StripeEvent.handle(event_json)
      end

      it 'saved the event' do
        expect(last_event.event_id).to eq 'test_evt_1'
        expect(last_event.object_id).to eq 'du_1Y7pRWBCJIIhvMWmv0ZPR9Ef'
        expect(last_event.event_time).to eq Time.now
      end

      it 'saves StripeDispute' do 
        expect(last_dispute.stripe_dispute_id).to eq 'du_1Y7pRWBCJIIhvMWmv0ZPR9Ef'
      end
    end

    describe 'funds_reinstated' do
      let(:event_json) { StripeMock.mock_webhook_event('charge.dispute.funds_reinstated')}

      let(:last_event) { StripeEvent.last}
      let(:last_dispute) { StripeDispute.last}
      let(:previous_event_object) {
        create(:stripe_event,
          event_id:"test_evt_old", 
          event_time: DateTime.now - 1.minutes, 
          object_id: 'dp_1Y75JUBCJIIhvMWmSRi5eQbU')
      }
      
      before(:each) do
        previous_event_object
        StripeEvent.handle(event_json)
      end

      it 'saved the event' do
        expect(last_event.event_id).to eq 'test_evt_1'
        expect(last_event.object_id).to eq 'dp_1Y75JUBCJIIhvMWmSRi5eQbU'
        expect(last_event.event_time).to eq Time.now
      end

      it 'saves StripeDispute' do 
        expect(last_dispute.stripe_dispute_id).to eq 'dp_1Y75JUBCJIIhvMWmSRi5eQbU'
      end
    end

    describe 'funds_withdrawn' do
      let(:event_json) { StripeMock.mock_webhook_event('charge.dispute.funds_withdrawn')}

      let(:last_event) { StripeEvent.last}
      let(:last_dispute) { StripeDispute.last}
      let(:previous_event_object) {
        create(:stripe_event,
          event_id:"test_evt_old", 
          event_time: DateTime.now - 1.minutes, 
          object_id: 'du_1Y7pRWBCJIIhvMWmv0ZPR9Ef')
      }
      
      before(:each) do
        previous_event_object
        StripeEvent.handle(event_json)
      end

      it 'saved the event' do
        expect(last_event.event_id).to eq 'test_evt_1'
        expect(last_event.object_id).to eq 'du_1Y7pRWBCJIIhvMWmv0ZPR9Ef'
        expect(last_event.event_time).to eq Time.now
      end

      it 'saves StripeDispute' do 
        expect(last_dispute.stripe_dispute_id).to eq 'du_1Y7pRWBCJIIhvMWmv0ZPR9Ef'
      end
    end

    describe 'closed-won' do
      let(:event_json) { StripeMock.mock_webhook_event('charge.dispute.closed-won')}

      let(:last_event) { StripeEvent.last}
      let(:last_dispute) { StripeDispute.last}
      let(:previous_event_object) {
        create(:stripe_event,
          event_id:"test_evt_old", 
          event_time: DateTime.now - 1.minutes, 
          object_id: 'dp_1Y75JUBCJIIhvMWmSRi5eQbU')
      }
      
      before(:each) do
        previous_event_object
        StripeEvent.handle(event_json)
      end

      it 'saved the event' do
        expect(last_event.event_id).to eq 'test_evt_1'
        expect(last_event.object_id).to eq 'dp_1Y75JUBCJIIhvMWmSRi5eQbU'
        expect(last_event.event_time).to eq Time.now
      end

      it 'saves StripeDispute' do 
        expect(last_dispute.stripe_dispute_id).to eq 'dp_1Y75JUBCJIIhvMWmSRi5eQbU'
      end
    end

    describe 'closed-lost' do
      let(:event_json) { StripeMock.mock_webhook_event('charge.dispute.closed-lost')}

      let(:last_event) { StripeEvent.last}
      let(:last_dispute) { StripeDispute.last}
      let(:previous_event_object) {
        create(:stripe_event,
          event_id:"test_evt_old", 
          event_time: DateTime.now - 1.minutes, 
          object_id: 'du_1Y7pRWBCJIIhvMWmv0ZPR9Ef')
      }
      
      before(:each) do
        previous_event_object
        StripeEvent.handle(event_json)
      end

      it 'saved the event' do
        expect(last_event.event_id).to eq 'test_evt_1'
        expect(last_event.object_id).to eq 'du_1Y7pRWBCJIIhvMWmv0ZPR9Ef'
        expect(last_event.event_time).to eq Time.now
      end

      it 'saves StripeDispute' do 
        expect(last_dispute.stripe_dispute_id).to eq 'du_1Y7pRWBCJIIhvMWmv0ZPR9Ef'
      end
    end
  end
end
