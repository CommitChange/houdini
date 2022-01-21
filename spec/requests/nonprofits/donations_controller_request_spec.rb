# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE
require 'rails_helper'

RSpec.describe Nonprofits::DonationsController, type: :request do
  

  def create_offsite_base_path(nonprofit_id)
    "/nonprofits/#{nonprofit_id}/donations/create_offsite"
  end

	around do |ex|
		Timecop.freeze(2020, 5, 4) do
			ex.run
		end
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
        response.body
      end

      describe 'result' do
        include_context 'with json results for transaction_for_donation' do 

          let(:expected_fees) { 0 }
        end

        it {
          is_expected.to include_json(generate_transaction_for_donation_json)
        }
      end

      describe 'object events' do
        subject(:transaction_event) do 
          get "/api_new/nonprofits/#{nonprofit.houid}/object_events", event_entity: transaction.houid
          response.body
        end

        it {
            is_expected.to include_json(
              data: [
                {
                  id: match_houid('evt'),
                  type: 'transaction.created',
                  created: be_a(Numeric),
                  object: 'object_event',
                  data: {
                    object: {
                      'id' => transaction.houid,
                      'supporter' => transaction.supporter.houid,

                      'subtransaction' => {
                        'id' => match_houid(:offlinetrx),
                        'amount' => {'cents' => 4000, 'currency' => 'usd'},
                        'payments' => [
                          {
                            'id' => match_houid(:offtrxchrg),
                            'gross_amount' => {'cents' => 4000, 'currency' => 'usd'},
                            'fee_total' => {'cents' => 0, 'currency' => 'usd'},
                            'net_amount' => {'cents' => 4000, 'currency' => 'usd'}
                          }
                        ]
                      },
                      'transaction_assignments' => [
                        {
                          'id' => match_houid('don')
                        }
                      ]
                    }
                  }
                }   
              ]
             )
            
          }
        # it {
        #   expect(transaction_event['data'].count).to eq 1
        # }

        # describe '-> data.first' do
        #   subject(:evt_data) {transaction_event['data'].first}
        #   it {
        #     is_expected.to include_json(
        #       data: {
              
        #         id: match_houid('evt'),
        #         type: 'transaction.created',
        #         created: be_a(Numeric),
        #         object: 'object_event',
        #         # data: include({
                  
        #         # }
        #       }
        #     )
        #   }

        #   describe '-> data -> object' do 
        #     subject(:object) { evt_data['data']['object']}
          
        #     it {
        #       is_expected.to include(
        #         'id' => transaction.houid,
        #         'supporter' => transaction.supporter.houid,

        #         'subtransaction' => include({
        #           'id' => match_houid(:offline_trx),
        #           'amount' => {'cents' => 4000, 'currency' => 'usd'},
        #           'payments' => [
        #             include({
        #               'id' => match_houid(:offtrxchrg),
        #               'gross_amount' => {'cents' => 4000, 'currency' => 'usd'},
        #               'fee_total' => {'cents' => 0, 'currency' => 'usd'},
        #               'net_total' => {'cents' => 4000, 'currency' => 'usd'}
        #             })
        #           ]
        #         }),
        #         'transaction_assignments' => [
        #           include({
        #             'id' => match_houid('don')
        #           })
        #         ]
        #       )
        #     }
        #   end
        # end
        
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