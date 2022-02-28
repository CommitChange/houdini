# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE
FactoryBot.define do
	factory :transaction do
		supporter { create(:supporter) }
	end

	factory :transaction_for_offline_donation, class: "Transaction" do
		transient do

			offline_transaction_charge { subtransaction.subtransaction_payments.first}
			payment {
				offline_transaction_charge&.legacy_payment
			}
			gross_amount { 4000 }
			fee_total { 0}
			nonprofit { supporter.nonprofit}

		end

		amount { gross_amount }

		supporter { create(:supporter_with_fv_poverty) }
		subtransaction { build(:subtransaction_for_offline_donation,
				supporter: supporter,
				gross_amount: gross_amount, 
				fee_total: fee_total)
		}

		transaction_assignments { 
			ta = [
				build(:transaction_assignment, 
					assignable: 
						build(:modern_donation,
							legacy_donation: 
								build(:donation, 
									supporter: supporter,
									amount: gross_amount,
									nonprofit:nonprofit, 
									designation: 'Designation 1',
									payment: payment,
								)
						)
				)
			]

			ta
		}
	end

	factory :transaction_for_stripe_donation, class: "Transaction" do
		
		transient do

			stripe_transaction_charge { subtransaction.subtransaction_payments.first}
			payment {
				stripe_transaction_charge&.legacy_payment
			}
			gross_amount { 4000 }
			fee_total { 0}
			nonprofit { supporter.nonprofit}

			stripe_charge_id { 'ch_1Y7zzfBCJIIhvMWmSiNWrPAC' }
			
		end

		supporter { create(:supporter_with_fv_poverty) }
		subtransaction { build(:subtransaction_for_stripe_donation,
				supporter: supporter,
				gross_amount: gross_amount, 
				fee_total: fee_total,
				stripe_charge_id: stripe_charge_id,
				date: date)
		}

		transaction_assignments { 
			ta = [
				build(:transaction_assignment, 
					assignable: 
						build(:modern_donation,
							amount: gross_amount,
							legacy_donation: 
								build(:donation, 
									supporter: supporter,
									amount: gross_amount,
									nonprofit:nonprofit, 
									designation: 'Designation 1',
									payment: payment,
								)
						)
				)
			]

			ta
		}

		amount { gross_amount}

		created { date }

		factory :transaction_for_stripe_dispute_of_22500 do
			transient do
				stripe_charge_id { "ch_1Y7vFYBCJIIhvMWmsdRJWSw5"}
				gross_amount { 22500 }
				fee_total { 0 }
				date { Time.new(2019, 8, 5) - 1.day}
			end
		end

		factory :transaction_for_stripe_dispute_of_80000 do
			transient do
				stripe_charge_id { "ch_1Y7zzfBCJIIhvMWmSiNWrPAC"}
				gross_amount { 80000 }
				fee_total { 0 }
				date { Time.at(1596429794) - 1.day}
			end
		end
	end

	factory :transaction_for_refund, class: "Transaction" do
		transient do

			stripe_transaction_charge { subtransaction.subtransaction_payments.first}
			payment {
				stripe_transaction_charge&.legacy_payment
			}
			gross_amount { 4000 }
			fee_total { -300}
			nonprofit { supporter.nonprofit}

		end

		supporter { create(:supporter_with_fv_poverty) }
		subtransaction { association :subtransaction_for_refund,
				gross_amount: gross_amount, 
				fee_total: fee_total,
				supporter: supporter
		}
	end

	factory :transaction_for_testing_payment_extensions, class: "Transaction" do
		transient do
			currency {'fake'}
			payments {[
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
		amount { 707 }
		nonprofit { build(:nonprofit, currency: currency)}
		subtransaction {
			build(:subtransaction, subtransaction_payments: payments)
		}
		
	end
end
