# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE
FactoryBot.define do
	factory :offline_transaction_charge, aliases: [:offline_transaction_charge_base] do
		inherit_from_transaction
		

		trait :inherit_from_payment do
			#association :offline_transaction, factory: :offline_transaction_base, :inherit_from_payment
		end

		trait :inherit_from_transaction do
			association :offline_transaction, factory: :offline_transaction_base

		end
		
	end
end
