# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
class RecurringDonation < ApplicationRecord
  # The status is confusing here.
  # A recurring donation can be in one of four status'
  # * active
  # * cancelled
  # * failed
  # * fulfilled

  # the conditions for those statuses are as follows
  # if the field 'active' is false, then "cancelled"
  # else if n_failures is at least 3, then "failed"
  # else if the end_date is set and in the past, "fulfilled"
  # else "active"

  # The query that displays in nonprofits/:id/recurring_donations is rds that are active OR failed

  # Slipflow charges some monthly gifts itself. Its first payment is a Slipflow PaymentIntent that
  # started a stripe_recurrence, and Slipflow writes this row, in the same transaction as the
  # stripe_recurrence, as a copy for CC's display, receipts and reports. CC owns only the cancel
  # (active, cancelled_at, cancelled_by) and refuses every other change, since Slipflow's
  # stripe_recurrence holds the gift's real terms. n_failures is set to 3 by Slipflow when it stops
  # the gift, so CC shows it as failed.
  #
  # CC's charger goes further and skips any donation with a Slipflow charge, so it can't charge a gift
  # whatever order Slipflow's rows become visible in.
  SLIPFLOW_EDIT_REFUSAL = "This recurring donation can only be cancelled. To change it, cancel it and give again."

  define_model_callbacks :cancel

  before_save :set_anonymous

  after_create :fire_recurring_donation_created

  after_cancel :fire_recurring_donation_cancelled

  attr_accessible \
    :amount, # int (cents)
    :active, # bool (whether this recurring donation should still be paid)
    :paydate, # int (fixed date of the month for monthly recurring donations)
    :interval, # int (interval of time, ie the '3' in '3 months')
    :time_unit, # str ('month', 'day', 'week', or 'year')
    :start_date, # date (when to start this recurring donation)
    :end_date, # date (when to deactivate this recurring donation)
    :n_failures, # int (how many times the charge has failed)
    :edit_token, # str / uuid to validate the editing page, linked from their email client
    :cancelled_by, # str email of user/supporter who made the cancellation
    :cancelled_at, # datetime of user/supporter who made the cancellation
    :donation_id, :donation,
    :nonprofit_id, :nonprofit,
    :supporter_id, # used because things are messed up in the datamodel
    :anonymous

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: [false, nil]) }
  scope :cancelled, -> { where(active: [false, nil]) }
  scope :monthly, -> { where(time_unit: "month", interval: 1) }
  scope :annual, -> { where(time_unit: "year", interval: 1) }
  scope :failed, -> { where("n_failures >= 3") }
  scope :unfailed, -> { where("n_failures < 3") }
  scope :fulfilled, -> { where("recurring_donations.end_date < ?", Time.current.to_date) }
  scope :unfulfilled, -> { where("recurring_donations.end_date IS NULL OR recurring_donations.end_date IS >= ?", Time.current.to_date) }

  scope :slipflow, -> { where(slipflow_clause) }
  scope :not_slipflow, -> { where.not(slipflow_clause) }

  scope :may_attempt_again, -> { where("recurring_donations.active AND (recurring_donations.end_date IS NULL OR recurring_donations.end_date > ?) AND recurring_donations.n_failures < 3", Time.current) }

  belongs_to :donation
  belongs_to :nonprofit
  has_many :charges, through: :donation
  has_one :card, through: :donation
  has_one :supporter, through: :donation
  has_one :misc_recurring_donation_info
  has_one :recurring_donation_hold
  has_many :activities, as: :attachment

  validates :paydate, numericality: {less_than: 29}, allow_blank: true
  validates :donation_id, presence: true
  validates :nonprofit_id, presence: true
  validates :start_date, presence: true
  validates :interval, presence: true, numericality: {greater_than: 0}
  validates :time_unit, presence: true, inclusion: {in: Timespan::Units}
  validates_associated :donation

  # SQL that's true when a recurring donation is Slipflow's
  def self.slipflow_clause
    "EXISTS (SELECT 1 FROM charges INNER JOIN stripe_recurrences ON stripe_recurrences.stripe_payment_intent_id = charges.stripe_payment_intent_id WHERE charges.donation_id = recurring_donations.donation_id)"
  end

  # SQL that's true when a recurring donation's donation has any Slipflow charge. CC's charger skips these.
  def self.slipflow_charged_clause
    "EXISTS (SELECT 1 FROM charges WHERE charges.donation_id = recurring_donations.donation_id AND charges.stripe_payment_intent_id IS NOT NULL)"
  end

  def slipflow?
    persisted? && RecurringDonation.slipflow.exists?(id)
  end

  def slipflow_charged?
    persisted? && RecurringDonation.where(RecurringDonation.slipflow_charged_clause).exists?(id)
  end

  def refuse_edit_if_slipflow!
    raise ParamValidation::ValidationError.new(SLIPFLOW_EDIT_REFUSAL, key: :id) if slipflow?
  end

  def most_recent_charge
    if charges
      charges.sort_by { |c| c.created_at }.last
    end
  end

  def most_recent_paid_charge
    if charges
      charges.find_all { |c| c.paid? }.sort_by { |c| c.created_at }.last
    end
  end

  def total_given
    if charges
      charges.find_all(&:paid?).sum(&:amount)
    end
  end

  def failed?
    n_failures >= 3
  end

  def cancelled?
    !active
  end

  # will this recurring donation be attempted again the next time it should be run?
  def will_attempt_again?
    !failed? && !cancelled? && (end_date.nil? || end_date > Time.current)
  end

  def cancel!(email)
    unless cancelled?
      run_callbacks(:cancel) do
        self.active = false
        self.cancelled_by = email
        self.cancelled_at = Time.current
        save!
      end
    end
  end

  # XXX let's make these monthly_totals a query
  # Or just push it into the front-end
  def self.monthly_total
    all.map(&:monthly_total).sum
  end

  def monthly_total
    multiple = {
      "week" => 4,
      "day" => 30,
      "year" => 0.0833
    }[interval] || 1
    donation.amount * multiple
  end

  private

  def set_anonymous
    update_attributes(anonymous: false) if anonymous.nil?
  end

  def fire_recurring_donation_created
    RecurringDonationCreatedJob.perform_later(self)
  end

  def fire_recurring_donation_cancelled
    RecurringDonationCancelledJob.perform_later(self)
  end
end
