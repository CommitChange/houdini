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
	has_many :donations, through: :transaction_assignments, source: :assignable, source_type: 'ModernDonation', inverse_of: 'trx'

	has_one :subtransaction
	has_many :payments, through: :subtransaction, source: :subtransaction_payments, class_name: 'SubtransactionPayment'

	has_many :object_events, as: :event_entity

	validates :supporter, presence: true

	# get payments in reverse chronological order
	def ordered_payments
		payments.ordered_query
	end

	def amount_as_money
    Amount.new(amount||0, nonprofit.currency)
  end

	# def designation
	# 	donation&.designation
	# end
	
	# def dedication
	# 	donation&.dedication
	# end

	def publish_created
		object_events.create( event_type: 'transaction.created')
	end

	def publish_updated
		object_events.create( event_type: 'transaction.updated')
	end

	def publish_deleted
		object_events.create( event_type: 'transaction.deleted')
	end

	private

	def to_param
		persisted? && houid
	end
end


ActiveSupport.run_load_hooks(:houdini_transaction, Transaction)
