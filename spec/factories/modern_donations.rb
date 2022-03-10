# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE
FactoryBot.define do
  factory :modern_donation do
    amount { 4000 }
  end
 
  factory :modern_donation_base, class: "ModernDonation" do
    amount { transaction_assignment.trx.subtransaction.ordered_payments.last.gross_amount }
    transaction_assignment { association :transaction_assignment_base }
    legacy_donation { transaction_assignment.trx.subtransaction.ordered_payments.last.legacy_payment.donation}
  end

end
