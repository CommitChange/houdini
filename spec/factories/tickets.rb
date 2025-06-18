# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
FactoryBot.define do
  factory :ticket do
    event_discount { association :event_discount_base }
    supporter { association :supporter_base }
    profile
    ticket_level { association :source_token_base }
    charge { association :charge_base }
    payment { association :payment_base }
    source_token
    ticket_purchase
    note { Faker::Lorem.sentence }

    trait :has_event do
      event
    end

    trait :has_card do
      card
    end
  end
end
