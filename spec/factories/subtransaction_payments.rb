# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE
FactoryBot.define do
	factory :subtransaction_payment do
		transient do
			gross_amount { 4000}
			
			fee_total { -300}
			net_amount { gross_amount + fee_total}
		end
		legacy_payment { build(:payment, gross_amount: gross_amount, net_amount: net_amount, fee_total: fee_total, date: Time.current) }
		paymentable { create(:offline_transaction_charge) }

		factory :subtransaction_payment_with_offline_charge do
			
			paymentable { create(:offline_transaction_charge) }
			payment { build(:payment, gross_amount: gross_amount, net_amount: net_amount, fee_total: fee_total, date: Time.current) }
		end
	end
end
