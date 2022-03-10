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
        include_context 'json results for transaction expectations'

        it {
          is_expected.to include_json(generate_transaction_json(
            nonprofit_houid: nonprofit.houid,
            supporter_houid: supporter.houid,
            transaction_houid: transaction.houid,
            subtransaction_expectation: {
              object: 'offline_transaction',
              houid: match_houid(:offlinetrx),
              charge_payment: {
                object: 'offline_transaction_charge',
                houid: match_houid(:offtrxchrg),
                gross_amount: 4000,
                fee_total: 0
              }
            },

            transaction_assignments: [
              {
                object: 'donation',
                houid: match_houid(:don),
                other_attributes: {
                  designation: "Designation 1"
                }
              }
            ]

          ))
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

    around(:each) do |ex|
       StripeMock.start
       ex.run
       StripeMock.stop
    end

    let(:supporter) {create(:supporter, nonprofit: nonprofit)}
    let(:nonprofit) { create(:nonprofit)}
    let(:user) { create(:user_base, roles: [build(:role_base, :as_nonprofit_associate, host: nonprofit)]) }
    
    let(:token) { create(:source_token_base, tokenizable: build(:card_base,  :with_created_stripe_customer_and_card, holder: supporter))}
    context 'with non-logged-in user' do

      def prepare_fee_eras
        create(:fee_era_with_structures)
      end
      
      subject(:main_response) {
        prepare_fee_eras
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

        let(:transaction) {
          payment_id = JSON.parse(main_response.body)['payment']['id']

          Payment.find(payment_id).trx
        }
        subject(:transaction_result) do 
          sign_in user
          get "/api_new/nonprofits/#{nonprofit.houid}/transactions/#{transaction.houid}"
          response.body
        end

        describe 'result' do
          include_context 'json results for transaction expectations'

          it {
            is_expected.to include_json(generate_transaction_json(
              nonprofit_houid: nonprofit.houid,
              supporter_houid: supporter.houid,
              transaction_houid: transaction.houid,
              subtransaction_expectation: {
                object: 'stripe_transaction',
                houid: match_houid(:stripetrx),
                charge_payment: {
                  object: 'stripe_transaction_charge',
                  houid: match_houid(:stripechrg),
                  gross_amount: 4000,
                  fee_total: -250
                }
              },

              transaction_assignments: [
                {
                  object: 'donation',
                  houid: match_houid(:don),
                  other_attributes: {
                    designation: "Designation 1"
                  }
                }
              ]

            ))
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
                        object: generate_transaction_json(
                          expand: [],
                          nonprofit_houid: nonprofit.houid,
                          supporter_houid: supporter.houid,
                          transaction_houid: transaction.houid,
                          subtransaction_expectation: {
                            object: 'stripe_transaction',
                            houid: match_houid(:stripetrx),
                            charge_payment: {
                              object: 'stripe_transaction_charge',
                              houid: match_houid(:stripechrg),
                              gross_amount: 4000,
                              fee_total: -250
                            }
                          },
                
                          transaction_assignments: [
                            {
                              object: 'donation',
                              houid: match_houid(:don),
                              other_attributes: {
                                designation: "Designation 1",
                                legacy_id: transaction.donations.first.legacy_id,
                                dedication: {
                                  note: "My mom",
                                  type: "honor"
                                },
                              }
                            }
                          ]
        
                        )
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


            # describe 'donation.created' do
            #   let(:donation) { transaction.donations.first}
            #   subject(:donation_event) do
            #     sign_in user
            #     get "/api_new/nonprofits/#{nonprofit.houid}/object_events", event_entity: donation.to_houid
            #     response.body
            #   end

            #   it {
            #     is_expected.to include_json(
            #       data: [
            #         {
            #           id: match_houid('evt'),
            #           type: 'donation.created',
            #           created: be_a(Numeric),
            #           object: 'object_event',
            #           data: {It seems like a you question
            #             object: {
            #               'id' => donation.to_houid,
            #               'supporter' => donation.supporter.houid,
            #               object: 'donation',
            #               'amount' => {'cents' => 4000, 'currency' => 'usd'},
            #               designation: 'Designation 1',
            #               legacy_id: donation.legacy_id,
            #               dedication: {
            #                 note: "My mom",
            #                 type: "honor"
            #               },
            #               # created: be_a(Numeric),
            #               transaction: {
            #                 subtransaction: {
            #                   id: match_houid(:stripetrx),
            #                   'amount' => {'cents' => 4000, 'currency' => 'usd'},
            #                   payments: [{id: match_houid(:stripechrg)}],
            #                   transaction: match_houid(:trx)
            #                 },
            #                 'transaction_assignments' => [
            #                   {
            #                     'id' => match_houid('don'),
            #                     designation: 'Designation 1',
            #                     legacy_id: donation.legacy_id,
            #                     dedication: {
            #                       note: "My mom",
            #                       type: "honor"
            #                     }
            #                   }
            #                 ]
            #               },
                          
            #             }
                        
            #           }
            #         }   
            #       ]
            #     ) 
            #   }
            # end
          end 
        end
      end
    end
  end
end