# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE
require 'rails_helper'

RSpec.describe Nonprofits::DonationsController, type: :request do
  
  def create_stripe_base_path(nonprofit_id)
    "/nonprofits/#{nonprofit_id}/donations"
  end

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
    let(:user) { create(:user_as_nonprofit_associate, nonprofit: nonprofit)  }
    context 'with nonprofit user' do
      before do
				sign_in user
        post create_offsite_base_path(nonprofit.id), {donation: {
          amount: 4000,
          supporter_id: supporter.id,
          nonprofit_id: nonprofit.id,
          designation: "Designation 1",
          dedication: {note: "My mom", type:"honor"}.to_json
        }}
      end

      let(:transaction) { 
        payment_id = JSON.parse(response.body)['payment']['id']
        Payment.find(payment_id).trx
      }

      subject(:transaction_result) do 
        
        get "/api_new/nonprofits/#{nonprofit.houid}/transactions/#{transaction.houid}"
        response.body
      end

      describe 'result' do
        include_context 'with json results for transaction_for_donation' do 

          let(:expected_fees) { 0 }
          let(:subtransaction_houid) {:offlinetrx}
          let(:subtransaction_object) {'offline_transaction'}
          let(:charge_houid) { :offtrxchrg}
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
                        'id' => match_houid('don'),
                        designation: 'Designation 1',
                        dedication: {
                          note: "My mom",
                          type: "honor"
                        }
                      }
                    ]
                  }
                }
              }   
            ]
          )
        }
        
      end 
    end

    context 'without nonprofit user' do 
      it 'returns unauthorized' do
				post create_offsite_base_path(nonprofit.id)
				expect(response).to have_http_status(302)
			end
    end
  end

  describe 'POST /create' do
    let!(:current_fee_era) { create(:fee_era_with_structures)}
    around(:each) do |ex|
       StripeMock.start
       ex.run
       StripeMock.stop
    end
    let(:supporter) {token.tokenizable.holder}
    let(:nonprofit) { supporter.nonprofit}
    let(:user) { create(:user_as_nonprofit_associate, nonprofit: nonprofit) }
    let(:token) { create(:source_token_for_supporter_for_fv_poverty)}
    context 'with non-logged-in user' do
      subject(:main_response) {
        post create_stripe_base_path(nonprofit.id), {donation: {
          amount: 4000,
          supporter_id: supporter.id,
          nonprofit_id: nonprofit.id,
          designation: "Designation 1",
          dedication: {note: "My mom", type:"honor"}.to_json
        }, token: token.token, amount: 4000}
        response
      }
      

      it {
        is_expected.to have_http_status(:ok)
      }
   

      context 'transaction json' do 
        let(:transaction) {  payment_id = JSON.parse(main_response.body)['payment']['id']
          Payment.find(payment_id).trx
        }
        subject(:transaction_result) do 
          sign_in user
          get "/api_new/nonprofits/#{nonprofit.houid}/transactions/#{transaction.houid}"
          response.body
        end

        describe 'result' do
          include_context 'with json results for transaction_for_donation' do 

            let(:expected_fees) { -250 }
            let(:subtransaction_houid) {:stripetrx}
            let(:subtransaction_object) {'stripe_transaction'}
            let(:charge_houid) { :stripechrg}
          end

          it {
            is_expected.to include_json(generate_transaction_for_donation_json)
          }

          describe 'object events' do
            describe 'transaction.created' do
              subject(:transaction_event) do
                sign_in user
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
                            'id' => match_houid(:stripetrx),
                            'amount' => {'cents' => 4000, 'currency' => 'usd'},
                            'payments' => [
                              {
                                'id' => match_houid(:stripechrg),
                                'gross_amount' => {'cents' => 4000, 'currency' => 'usd'},
                                'fee_total' => {'cents' => -250, 'currency' => 'usd'},
                                'net_amount' => {'cents' => 3750, 'currency' => 'usd'}
                              }
                            ]
                          },
                          'transaction_assignments' => [
                            {
                              'id' => match_houid('don'),
                              designation: 'Designation 1',
                              legacy_id: transaction.donations.first.legacy_id,
                              dedication: {
                                note: "My mom",
                                type: "honor"
                              }
                            }
                          ]
                        }
                      }
                    }   
                  ]
              )
              
              }
            end

            describe 'stripe_transaction_charge.created' do
              let(:stripe_charge) { transaction.payments.first}
              subject(:charge_event) do
                sign_in user
                get "/api_new/nonprofits/#{nonprofit.houid}/object_events", event_entity: stripe_charge.to_houid
                response.body
              end

              it {

                is_expected.to include_json(
                  data: [
                    {
                      id: match_houid('evt'),
                      type: 'stripe_transaction_charge.created',
                      created: be_a(Numeric),
                      object: 'object_event',
                      data: {
                        object: {
                          'id' => stripe_charge.to_houid,
                          'supporter' => stripe_charge.supporter.houid,
                          'gross_amount' => {'cents' => 4000, 'currency' => 'usd'},
                          'fee_total' => {'cents' => -250, 'currency' => 'usd'},
                          'net_amount' => {'cents' => 3750, 'currency' => 'usd'},
                          created: be_a(Numeric),
                          subtransaction: {
                            id: match_houid(:stripetrx),
                            'amount' => {'cents' => 4000, 'currency' => 'usd'},
                            payments: [{id: stripe_charge.to_houid}],
                            transaction: {
                              'amount' => {'cents' => 4000, 'currency' => 'usd'},
                              'transaction_assignments' => [
                                {
                                  'id' => match_houid('don'),
                                  designation: 'Designation 1',
                                  legacy_id: transaction.donations.first.legacy_id,
                                  dedication: {
                                    note: "My mom",
                                    type: "honor"
                                  }
                                }
                              ]
                            }
                          }
                        }
                      }
                    }   
                  ]
                ) 
              }
            end

            describe 'donation.created' do
              let(:donation) { transaction.donations.first}
              subject(:donation_event) do
                sign_in user
                get "/api_new/nonprofits/#{nonprofit.houid}/object_events", event_entity: donation.to_houid
                response.body
              end

              it {
                is_expected.to include_json(
                  data: [
                    {
                      id: match_houid('evt'),
                      type: 'donation.created',
                      created: be_a(Numeric),
                      object: 'object_event',
                      data: {
                        object: {
                          'id' => donation.to_houid,
                          'supporter' => donation.supporter.houid,
                          object: 'donation',
                          'amount' => {'cents' => 4000, 'currency' => 'usd'},
                          designation: 'Designation 1',
                          legacy_id: donation.legacy_id,
                          dedication: {
                            note: "My mom",
                            type: "honor"
                          },
                          # created: be_a(Numeric),
                          transaction: {
                            subtransaction: {
                              id: match_houid(:stripetrx),
                              'amount' => {'cents' => 4000, 'currency' => 'usd'},
                              payments: [{id: match_houid(:stripechrg)}],
                              transaction: match_houid(:trx)
                            },
                            'transaction_assignments' => [
                              {
                                'id' => match_houid('don'),
                                designation: 'Designation 1',
                                legacy_id: donation.legacy_id,
                                dedication: {
                                  note: "My mom",
                                  type: "honor"
                                }
                              }
                            ]
                          },
                          
                        }
                        
                      }
                    }   
                  ]
                ) 
              }
            end
          end 
        end
      end
    end
  end
end