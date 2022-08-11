# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
FactoryBot.define do
  factory :ticket do

    trait :has_event do
      event
    end

    trait :has_card do
      card
    end
  end
end
