# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
# Payouts record a credit of the total pending balance on a nonprofit's account
# to their bank account or debit card
#
# These are tied to Stripe transfers

class Payout < ActiveRecord::Base

	belongs_to :nonprofit
	has_one    :bank_account, through: :nonprofit
	has_many   :payment_payouts, inverse_of: :payout
	has_many   :payments, through: :payment_payouts

	validates :stripe_transfer_id, uniqueness: true
	validates :nonprofit, presence: true
	validates :bank_account, presence: true
	validates :email, presence: true
	validates :net_amount, presence: true, numericality: {greater_than: 0}
	validate  :nonprofit_must_be_vetted, on: :create
	validate  :nonprofit_must_have_identity_verified, on: :create
	validate  :bank_account_must_be_confirmed, on: :create

	accepts_nested_attributes_for :payment_payouts

	scope :pending, -> {where(status: 'pending')}
	scope :paid,    -> {where(status: ['paid', 'succeeded'])}

	# Older transfers use the Stripe::Transfer object, newer use Stripe::Payout object
	def transfer_type
		if (stripe_transfer_id.start_with?('tr_') || stripe_transfer_id.start_with?('test_tr_'))
			return :transfer
		elsif (stripe_transfer_id.start_with?('po_') || stripe_transfer_id.start_with?('test_po_'))
			return :payout
		end
	end

	def bank_account_must_be_confirmed
		if self.bank_account && self.bank_account.pending_verification
			self.errors.add(:bank_account, 'must be confirmed via email')
		end
	end

	def nonprofit_must_have_identity_verified
		self.errors.add(:nonprofit, "must be verified") unless self.nonprofit && self.nonprofit&.stripe_account&.payouts_enabled
	end

	def nonprofit_must_be_vetted
		self.errors.add(:nonprofit, "must be vetted") unless self.nonprofit && self.nonprofit.vetted 
	end

end

