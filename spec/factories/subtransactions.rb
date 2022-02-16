# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE
FactoryBot.define do
	factory :subtransaction do
		
		subtransactable { create(:offline_transaction) }
		subtransaction_payments do
			[
				build(:subtransaction_payment_with_offline_charge)
			]
		end

		factory :subtransaction_for_testing_payment_extensions do
			transient do
				currency {'fake'}
			end

			trx {build(:transaction, nonprofit: build(:fv_poverty, currency: currency))}
			subtransaction_payments {[
				build(:subtransaction_payment, 
					gross_amount: 101,
					fee_total: -1),
				build(:subtransaction_payment,
				gross_amount: 202,
				fee_total: -2),
				build(:subtransaction_payment,
					gross_amount: 404,
					fee_total: -4)
			] }
		end
	end
end
