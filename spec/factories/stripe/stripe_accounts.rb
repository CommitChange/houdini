# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
FactoryBot.define do
  factory :__stripe_account, aliases: [:stripe_account_base] do
    stripe_object_base
  end
end