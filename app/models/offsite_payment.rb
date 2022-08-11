# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
class OffsitePayment < ActiveRecord::Base

	attr_accessible :gross_amount, :kind, :date, :check_number
	belongs_to :payment, dependent: :destroy
	belongs_to :donation
	belongs_to :nonprofit
	belongs_to :supporter

end
