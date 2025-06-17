# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
FactoryBot.define do
  factory :ticket_level do
    name { Faker::Lorem.words(number: 3) }
    event

    trait :has_tickets do
    end
  end
end
