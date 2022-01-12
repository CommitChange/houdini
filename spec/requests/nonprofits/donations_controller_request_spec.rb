# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE
require 'rails_helper'

RSpec.describe Nonprofits::DonationsController, type: :request do
  

  def create_offsite_base_path(nonprofit_id)
    "/nonprofits/#{nonprofit_id}/donations/create_offsite"
  end
  describe 'POST /create_offsite' do
    let(:supporter) {create(:supporter_with_fv_poverty)}
    let(:nonprofit) { supporter.nonprofit}
    let(:user) { create(:user) }
    context 'with nonprofit user' do
      before do
				user.roles.create(name: 'nonprofit_associate', host: nonprofit)
				sign_in user
        post create_offsite_base_path(nonprofit.id), {donation: {
          amount: 4000,
          supporter_id: supporter.id,
          nonprofit_id: nonprofit.id
        }}
      end

      let(:transaction) { payment_id = JSON.parse(response.body)['payment']['id']
        Payment.find(payment_id).trx
    }

      subject(:transaction_result) do 
        
        get "/api_new/nonprofits/#{nonprofit.houid}/transactions/#{transaction.houid}"
        JSON.parse(response.body)
      end

      describe 'result' do
        include_context 'with json results for transaction_for_donation' do 
          let(:item) { transaction_result}

          let(:expected_fees) { 0 }
        end
      end
    end

    context 'without nonprofit user' do 
      it 'returns unauthorized' do
				post create_offsite_base_path(nonprofit.id)
				expect(response).to have_http_status(302)
			end
    end
  end
end