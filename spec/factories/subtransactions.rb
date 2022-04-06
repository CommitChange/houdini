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

		factory :subtransaction_for_offline_donation, class: "Subtransaction" do
			transient do
				nonprofit {supporter.nonprofit}
				supporter { create(:supporter_with_fv_poverty)}
				gross_amount { 4000}
				fee_total { 0}
				net_amount {gross_amount+ fee_total}
			end
			subtransactable {
				build(:offline_transaction, amount: gross_amount)
	
			}
	
			subtransaction_payments {[ 
				build(:subtransaction_payment_for_offline_transaction_charge,
				subtransaction: @instance,
					gross_amount: gross_amount, 
				fee_total: fee_total, 
				nonprofit:nonprofit, 
				supporter:supporter)
	
			]}
		end

		factory :subtransaction_for_stripe_donation, class: "Subtransaction" do
			transient do
				nonprofit {supporter.nonprofit}
				supporter { create(:supporter_with_fv_poverty)}
				gross_amount { 4000}
				fee_total { 0}
				net_amount {gross_amount+ fee_total}
				stripe_charge_id { 'ch_1Y7zzfBCJIIhvMWmSiNWrPAC' }
				date { Time.current }
			end

			created { date }
			subtransactable {
				build(:stripe_transaction, amount: gross_amount)
	
			}
	
			subtransaction_payments {[ 
				build(:subtransaction_payment_for_stripe_transaction_charge,
				subtransaction: @instance,
					gross_amount: gross_amount, 
				fee_total: fee_total, 
				nonprofit:nonprofit, 
				supporter:supporter,
				stripe_charge_id: stripe_charge_id,
				date: date
				)
				
			]}
		end

		factory :subtransaction_for_refund,  class: "Subtransaction" do
			transient do
				nonprofit {supporter.nonprofit}
				supporter { build(:subtransaction_payment_for_offline_transaction_charge)}
			# 	initial_payment { 	
			# 		build(:subtransaction_payment, paymentable: 
			# 		build(
			# 			:stripe_transaction_charge, 
	
			# 			gross_amount: gross_amount, 
			# 		fee_total: fee_total, 
			# 		nonprofit:nonprofit, 
			# 		supporter:supporter)
			# 		)
	
			# }
	
				gross_amount { 4000}
				fee_total { -300}
				net_amount {gross_amount+ fee_total}
			end
			subtransactable {
				build(:stripe_transaction, amount: gross_amount)
	
			}
	
			subtransaction_payments {[ 
				association(:subtransaction_payment_for_refund_initial_charge,
				subtransaction: @instance,
					gross_amount: gross_amount, 
				fee_total: fee_total, 
				nonprofit:nonprofit, 
				supporter:supporter)
	
			]}
		end
	end

	factory :subtransaction_base, class: 'Subtransaction' do
		transient do
		# 	gross_amount { 400}
		# 	supporter { association :supporter_base }
			
		# end
		# # trx { association :transaction_base}
		# # subtransactable {
		# # 	build(:offline_transaction_base, subtransaction: @instance, amount: gross_amount)
		# # }
		# # subtransaction_payments {[
		# # 	build(:subtransaction_payment_base, gross_amount: gross_amount, subtransaction: @instance)
		# # ]}

		# trait :inherit_from_transaction do
		# 	trx { association :transaction_base}
		# 	subtransactable {association :offline_transaction_base, subtransaction: @instance, amount: gross_amount}
		# end
		# trait :receive_donation do
		# 	transient do
		# 		donation { nil}
		# 	end

		# 	subtransaction_payments {
		# 	[
		# 		build(:subtransaction_payment_base,
		# 			subtransaction: @instance,
		# 			legacy_payment: donation.payment,
		# 			paymentable: build(:stripe_transaction_charge, legacy_payment: donation.payment)
		# 		)
		# 	]}

		
			
		# end


		# trait :generate_donation do 
		# 	receive_donation
		# 	transient do
		# 		gross_amount {4000}
		# 		fee_total {-300}
		# 		date { Time.new(2020, 5, 4)}
		# 		stripe_charge_id { "ch_1Y7zzfBCJIIhvMWmSiNWrPAC"}
		# 		donation { 
		# 			create(:donation_base, :with_charge)}
		# 	end

		# 	supporter { donation.supporter}

		

		# 	subtransaction_payments {
		# 	[
		# 		build(:subtransaction_payment_base,
		# 			subtransaction: @instance,
		# 			legacy_payment: donation.payment,
		# 			paymentable: build(:stripe_transaction_charge, legacy_payment: donation.payment)
		# 		)
		# 	]}

		# end
		# trait :with_payments do
		# 	payment_descs {
		# 			[{props: [:subtransaction_payment_base], opts:{}}]
		# 	}

		# 	subtransaction_payments do
		# 		payment_desc.map do |desc|
		# 			build(*desc[:props], **desc[:opts], subtransaction: @instance)
		# 		end
		# 	end
		# end

			legacy_payment {nil}
		end

		after(:build) do |instance, evaluator|
			instance.subtransactable = evaluator.legacy_payment&.charge ? build(:stripe_transaction_base, amount: evaluator.legacy_payment.gross_amount) : build(:offline_transaction_base, amount: evaluator.legacy_payment.gross_amount)
			instance.subtransaction_payments << build(:subtransaction_payment_base, legacy_payment: evaluator.legacy_payment)
		end
	end

end
