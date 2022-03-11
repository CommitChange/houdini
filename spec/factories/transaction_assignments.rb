# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE
FactoryBot.define do
  factory :transaction_assignment do
    assignable { build(:modern_donation) }
  end

  factory :transaction_assignment_base, class: "TransactionAssignment" do
    transient do
      amount { 400}
    end
    trx { association :transaction_base }
    assignable {association :modern_donation_base, amount:amount, transaction_assignment: @instance}

    trait :legacy_donation do 
      donation { association :donation, supporter: trx.supporter, nonprofit: trx.nonprofit}
    end
  end

end
