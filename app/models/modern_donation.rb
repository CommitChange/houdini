# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE
class ModernDonation < ApplicationRecord
  include Model::TrxAssignable
  setup_houid :don, :houid

	# TODO must associate with events and campaigns somehow
	belongs_to :legacy_donation, class_name: 'Donation', foreign_key: :donation_id, inverse_of: :modern_donation

	delegate :designation, :dedication, to: :legacy_donation

	def amount
		legacy_donation.amount
	end

	def amount_as_money
		Amount.new(amount, currency)
	end
end
