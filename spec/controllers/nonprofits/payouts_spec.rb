# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
require 'rails_helper'
require 'controllers/support/shared_user_context'
require 'support/payments_for_a_payout'

describe Nonprofits::PayoutsController, :type => :controller do
  include_context :shared_user_context
  describe 'rejects unauthenticated users' do
    describe 'create' do
      include_context :open_to_np_admin, :post, :create, nonprofit_id: :__our_np
    end

    describe 'index' do
      include_context :open_to_np_associate, :get, :index, nonprofit_id: :__our_np, without_json_view: true
    end

    describe 'show' do
      include_context :open_to_np_associate, :get, :show, nonprofit_id: :__our_np, id: '1'
    end
  end

  describe '#create' do
    include_context 'payments for a payout'
    around(:each) do |example|
      StripeMockHelper.mock do
        example.run
      end
    end

    let(:payments) { available_payments_two_days_ago}
    

    let(:user_as_admin) { create(:user_as_nonprofit_admin, nonprofit: nonprofit)}
    let(:nonprofit) {
      create(:nonprofit,  bank_account: create(:bank_account))
    }

    let(:stripe_account) { create(:stripe_account, :with_verified_and_bank_provided_but_future_requirements, payouts_enabled: true)}
    before(:each) do
      payments
      nonprofit.stripe_account_id = stripe_account.stripe_account_id
      nonprofit.save!
      nonprofit.reload
      sign_in user_as_np_admin
      user_as_np_admin.current_sign_in_ip =  "1.1.1.1" # required by the call
      user_as_np_admin.save!
    end

    let(:payout_create) {
      post :create, {
        nonprofit_id: nonprofit.id,
        format: :json
      }
    }

    context "when payout works" do

      it 'will increase Payouts by one' do 
        expect { payout_create }.to change{ Payout.count}.by 1
      end

      it 'will increase the number of PaymentPayouts' do
        expect { payout_create }.to change{ PaymentPayout.count}.by 18
      end
      
      it 'sets the http status to :ok' do
        payout_create
        expect(response).to have_http_status(:ok)
      end
    end

    context "when payout fails at stripe" do 
      before(:each) do
        StripeMockHelper.prepare_error(Stripe::StripeError.new(message='some failure message'), :new_payout)
      end

      it 'increases Payouts by one' do 
        expect { payout_create }.to change{ Payout.count}.by 1
      end

      it 'does not change the number of PaymentPayouts' do
        expect { payout_create }.to_not change{ PaymentPayout.count}
      end

      it 'sets the http status to :unprocessible_entity' do
        payout_create
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end