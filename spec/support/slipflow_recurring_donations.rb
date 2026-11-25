# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later

# Builds the rows Slipflow writes for a monthly gift's first payment. CC has no models for
# payment_intents, stripe_payment_intents or stripe_recurrences, so these go in with Qx.
module SlipflowRecurringDonations
  # A recurring donation with only the columns Slipflow writes, its first payment two months ago
  def create_slipflow_recurring_donation(nonprofit: force_create(:nonprofit), **attributes)
    supporter = force_create(:supporter, nonprofit: nonprofit, email: "donor@example.com")
    donation = force_create(:donation, nonprofit: nonprofit, supporter: supporter, amount: 1000, recurring: true)
    add_slipflow_charge(donation, charged_at: 2.months.ago)
    row = Qx.insert_into(:recurring_donations).values({
      donation_id: donation.id, nonprofit_id: nonprofit.id, supporter_id: supporter.id, email: supporter.email,
      amount: 1000, active: true, n_failures: 0, interval: 1, time_unit: "month", start_date: 2.months.ago.to_date,
      paydate: 2.months.ago.day, edit_token: SecureRandom.uuid, anonymous: false
    }.merge(attributes)).ts.returning("id").ex.first
    RecurringDonation.find(row["id"])
  end

  # A charge for a Slipflow PaymentIntent and, unless start_recurrence is false, the stripe_recurrence it started
  def add_slipflow_charge(donation, charged_at: Time.current, start_recurrence: true)
    stripe_payment_intent_id = "pi_#{SecureRandom.hex(8)}"
    stripe_account = force_create(:stripe_account, stripe_account_id: "acct_#{SecureRandom.hex(8)}")
    Qx.insert_into(:stripe_payment_intents).values(id: stripe_payment_intent_id, stripe_account_id: stripe_account.stripe_account_id).ts.ex
    Qx.insert_into(:charges).values(
      donation_id: donation.id, supporter_id: donation.supporter_id, nonprofit_id: donation.nonprofit_id, amount: donation.amount,
      status: "paid", stripe_payment_intent_id: stripe_payment_intent_id, created_at: charged_at, updated_at: charged_at
    ).ex
    return unless start_recurrence

    payment_intent = Qx.insert_into(:payment_intents).values(nonprofit_id: donation.nonprofit_id, stripe_payment_intent_id: stripe_payment_intent_id).ts.returning("id").ex.first
    Qx.insert_into(:stripe_recurrences).values(
      gift_amount: donation.amount, start_time: charged_at, payment_intent_id: payment_intent["id"], stripe_payment_intent_id: stripe_payment_intent_id,
      stripe_account_id: stripe_account.id, stripe_customer_id: "cus_#{SecureRandom.hex(8)}", stripe_payment_method_id: "pm_#{SecureRandom.hex(8)}"
    ).ts.ex
  end
end

RSpec.configure { |config| config.include SlipflowRecurringDonations }
