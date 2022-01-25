# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE
FactoryBot.define do
	factory :transaction do
		supporter { create(:supporter) }
	end

	factory :transaction_for_donation, class: "Transaction" do

		amount { 4000 }
		supporter { create(:supporter_with_fv_poverty) }
		subtransaction { build(
			:subtransaction, subtransaction_payments: [
				build(:subtransaction_payment, paymentable: build(:offline_transaction_charge), legacy_payment: transaction_assignments.first.assignable.legacy_donation.payment)
			]
		)}

		transaction_assignments { 
		ta = [
			build(:transaction_assignment, assignable: build(:modern_donation, legacy_donation: build(:donation, supporter: supporter, amount: 4000, nonprofit:nonprofit, 
					payment: build(:payment, gross_amount: 4000, fee_total: -300, net_amount: 3700, nonprofit: nonprofit, supporter: supporter, date: Time.current)
				))
			)
		]

	ta
	}
	end
end
