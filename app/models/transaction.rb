# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE
class Transaction < ApplicationRecord
	include Model::CreatedTimeable
	include Model::Houidable

	setup_houid :trx, :houid
	
	belongs_to :supporter
	has_one :nonprofit, through: :supporter

	validates :supporter, presence: true

	def amount_as_money
    Amount.new(amount||0, nonprofit.currency)
  end

	private 
	def set_created_if_needed
		write_attribute(:created, Time.now) unless read_attribute(:created)
	end

	def to_param
		persisted? && houid
	end
end


ActiveSupport.run_load_hooks(:houdini_transaction, Transaction)
