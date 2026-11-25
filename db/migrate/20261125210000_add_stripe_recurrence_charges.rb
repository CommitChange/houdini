class AddStripeRecurrenceCharges < ActiveRecord::Migration[7.1]
  def change
    create_table :stripe_recurrence_charges, comment: "One row per attempt to charge a monthly gift for a month, written and committed before Stripe is called. A month has at most one row that isn't declined, failed or canceled; a job that can't insert it stops" do |t|
      t.references :stripe_recurrence, null: false, foreign_key: true, index: false, comment: "The monthly gift this charge is for"
      t.date :billing_month, null: false, comment: "The month charged for: the first day of billing_date's month (UTC)"
      t.date :billing_date, null: false, comment: "The day the gift was due (UTC)"
      t.integer :amount, comment: "What the donor is charged, in cents, with any fee they cover, as it was when the row was written; null only when skipped"
      t.integer :application_fee_amount, comment: "The platform fee on this charge, in cents, as it was when the row was written; null only when skipped"
      t.references :fee_era, foreign_key: true, type: :integer, comment: "The FeeEra application_fee_amount was worked out in; null only when skipped"
      t.string :idempotency_key, index: {unique: true}, comment: "The Stripe idempotency key for this attempt; null only when skipped"
      t.references :stripe_payment_intent, foreign_key: true, index: {unique: true}, type: :string, comment: "The local copy of the Stripe::PaymentIntent, set once Stripe has created it and before it's confirmed"
      t.string :status, null: false, default: "pending", comment: "pending until Stripe's answer is known, which includes after an error that leaves it unknown whether the card was charged; then succeeded, processing, requires_action, declined, failed (Stripe confirmed nothing was charged), canceled, or skipped (never sent to Stripe; see skip_reason)"
      t.string :skip_reason, comment: "Why a skipped month wasn't charged, like the gift's first payment being refunded or disputed"
      t.string :failure_code, comment: "Stripe's error code when the charge was declined or failed"
      t.string :decline_code, comment: "Stripe's decline code when the card was declined"
      t.string :failure_message, comment: "Stripe's error message when the charge was declined or failed"
      t.timestamps
      t.index [:stripe_recurrence_id, :billing_month], unique: true, where: "status NOT IN ('declined', 'failed', 'canceled')", name: "index_stripe_recurrence_charges_on_recurrence_and_month_live"
      t.index :updated_at, where: "status = 'pending'", name: "index_stripe_recurrence_charges_pending_on_updated_at"
      t.check_constraint "EXTRACT(DAY FROM billing_month) = 1", name: "stripe_recurrence_charges_billing_month_first_day"
      t.check_constraint "billing_date >= billing_month AND billing_date < (billing_month + INTERVAL '1 month')", name: "stripe_recurrence_charges_billing_date_in_month"
      t.check_constraint "amount > 0", name: "stripe_recurrence_charges_amount_positive"
      t.check_constraint "application_fee_amount >= 0", name: "stripe_recurrence_charges_application_fee_amount_not_negative"
      t.check_constraint "status <> 'skipped' OR (amount IS NULL AND application_fee_amount IS NULL AND fee_era_id IS NULL AND idempotency_key IS NULL)", name: "stripe_recurrence_charges_no_charge_details_when_skipped"
      t.check_constraint "(status = 'skipped') OR (amount IS NOT NULL AND application_fee_amount IS NOT NULL AND fee_era_id IS NOT NULL AND idempotency_key IS NOT NULL)", name: "stripe_recurrence_charges_charge_details_when_charged"
      t.check_constraint "status IN ('pending', 'succeeded', 'processing', 'requires_action', 'declined', 'failed', 'canceled', 'skipped')", name: "stripe_recurrence_charges_status_known"
      t.check_constraint "status NOT IN ('succeeded', 'processing', 'requires_action', 'declined', 'canceled') OR stripe_payment_intent_id IS NOT NULL", name: "stripe_recurrence_charges_payment_intent_once_confirmed"
      t.check_constraint "status <> 'skipped' OR stripe_payment_intent_id IS NULL", name: "stripe_recurrence_charges_no_payment_intent_when_skipped"
      t.check_constraint "(status = 'skipped') = (skip_reason IS NOT NULL)", name: "stripe_recurrence_charges_skip_reason_when_skipped"
    end
  end
end
