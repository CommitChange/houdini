# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE
class Transaction < ApplicationRecord
	include Model::CreatedTimeable
	include Model::Houidable

	setup_houid :trx, :houid
	
	belongs_to :supporter
	has_one :nonprofit, through: :supporter

	has_many :transaction_assignments, inverse_of: 'trx'
	has_one :subtransaction
	has_many :subtransaction_payments, through: :subtransaction

	validates :supporter, presence: true

	def amount_as_money
    subtransaction.amount_as_money
  end

	def amount
		subtransaction.amount
	end

	private

	def to_param
		persisted? && houid
	end
end


ActiveSupport.run_load_hooks(:houdini_transaction, Transaction)
