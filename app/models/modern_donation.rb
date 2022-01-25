# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE
class ModernDonation < ApplicationRecord
  include Model::TrxAssignable
  setup_houid :don, :houid

	# TODO must associate with events and campaigns somehow
	belongs_to :legacy_donation, class_name: 'Donation', foreign_key: :donation_id, inverse_of: :modern_donation

	delegate :designation, :dedication, :comment, :amount, to: :legacy_donation


	def dedication
		begin
			JSON::parse legacy_donation.dedication
		rescue
			nil
		end
	end

	def legacy_id
		legacy_donation.id
	end

	def amount_as_money
		Amount.new(amount, currency)
	end

	def publish_created
		object_events.create( event_type: 'donation.created')
	end

	def publish_updated
		object_events.create( event_type: 'donation.updated')
	end

	def publish_deleted
		object_events.create( event_type: 'donation.deleted')
	end
end
