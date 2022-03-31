# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE
FactoryBot.define do
  factory :transaction_assignment do
    assignable { build(:modern_donation) }
  end

  factory :transaction_assignment_base, class: "TransactionAssignment" do
    inherit_from_transaction

    trait :inherit_from_transaction do 
      trx { association :transaction_base}
      assignable {association :modern_donation_base, transaction_assignment: @instance}
    end

    trait :receive_donation do
      transient do
        donation {nil}
      end
      assignable {association :modern_donation_base, legacy_donation: donation, transaction_assignment: @instance}
    end
  end

end
