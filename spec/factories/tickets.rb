# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
FactoryBot.define do
  factory :ticket do
    event_discount
    supporter
    profile
    ticket_level
    charge
    payment
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
