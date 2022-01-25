# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
FactoryBot.define do
  factory :card do
    transient do
      stripe_helper {  StripeMock.create_test_helper }
      sequence(:stripe_customer_object) {
        Stripe::Customer.create
      }
      
      stripe_card_object {
        Stripe::Customer.create_source(
          stripe_customer_object.id, {
            source:stripe_helper.generate_card_token 
          }
        )
      }

    end
  
      factory :active_card_1 do
        name {'card 1'}
      end
      factory :active_card_2 do
        name { 'card 1'}
      end
      factory :inactive_card do
        name {'card 1'}
        inactive {true}
      end

      stripe_customer_id { stripe_customer_object.id }
      
      stripe_card_id { stripe_card_object.id}
     

      # before(:create) do|model
      # end

      # # sequence(:stripe_customer_id) do
      # #   #Stripe::Card.retrieve(id).customer.id
      # # end

  end
end
