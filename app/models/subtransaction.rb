# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE
class Subtransaction < ApplicationRecord
	include Model::CreatedTimeable

	belongs_to :trx, class_name: 'Transaction', foreign_key: 'transaction_id', inverse_of: :subtransaction
	has_one :supporter, through: :trx
	has_one :nonprofit, through: :trx
	delegate :currency, to: :nonprofit

	belongs_to :subtransactable, polymorphic: true

	has_many :subtransaction_payments # rubocop:disable Rails/HasManyOrHasOneDependent

	delegated_type :subtransactable, types: %w[OfflineTransaction]


	def amount_as_money
		Amount.new(amount, currency)
	end

	def amount
		subtransaction_payments.map{|i| i.gross_amount}.sum
	end
end
