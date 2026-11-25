class RecurringDonationHold < ApplicationRecord
  # attr_accessible :title, :body
  attr_accessible :end_date
  belongs_to :recurring_donation

  validate :recurring_donation_not_slipflow

  private

  # Slipflow schedules its own charges, so a hold on its recurring donation would do nothing
  def recurring_donation_not_slipflow
    errors.add(:recurring_donation, "is charged by Slipflow and can't be held") if recurring_donation&.slipflow?
  end
end
