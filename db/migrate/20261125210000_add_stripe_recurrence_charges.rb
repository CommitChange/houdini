class AddStripeRecurrenceCharges < ActiveRecord::Migration[7.1]
  def change
    create_table :stripe_recurrence_charges, comment: "One row per monthly gift per month. Written and committed before Stripe is called; a second job that can't insert the month's row stops" do |t|
      t.references :stripe_recurrence, null: false, foreign_key: true, index: false, comment: "The monthly gift this charge is for"
      t.date :billing_month, null: false, comment: "The month charged for, as its first day (UTC)"
      t.date :billing_date, null: false, comment: "The day in billing_month the gift was due"
      t.integer :amount, null: false, comment: "What the donor is charged, in cents, with any fee they cover, as it was when the row was written"
      t.integer :application_fee_amount, null: false, comment: "The platform fee on this charge, in cents, as it was when the row was written"
      t.references :fee_era, null: false, foreign_key: true, index: false, type: :integer, comment: "The FeeEra application_fee_amount was worked out in"
      t.integer :attempt, null: false, default: 1, comment: "Which attempt this month's charge is on. Starts at 1; a manual retry after a decline adds 1"
      t.string :idempotency_key, null: false, index: {unique: true}, comment: "The Stripe idempotency key for the current attempt"
      t.references :stripe_payment_intent, foreign_key: true, index: {unique: true}, type: :string, comment: "The local copy of the Stripe::PaymentIntent, set once Stripe has created it and before it's confirmed"
      t.string :status, null: false, default: "pending", comment: "pending until confirmed; then succeeded, processing, requires_action, declined, failed (any other error), canceled, or skipped (not charged; see skip_reason)"
      t.string :skip_reason, comment: "Why a skipped month wasn't charged, like the gift's first payment being refunded or disputed"
      t.string :failure_code, comment: "Stripe's error code when the charge was declined or failed"
      t.string :decline_code, comment: "Stripe's decline code when the card was declined"
      t.string :failure_message, comment: "Stripe's error message when the charge was declined or failed"
      t.timestamps
      t.index [:stripe_recurrence_id, :billing_month], unique: true, name: "index_stripe_recurrence_charges_on_recurrence_and_month"
      t.index :updated_at, where: "status = 'pending'", name: "index_stripe_recurrence_charges_pending_on_updated_at"
      t.check_constraint "EXTRACT(DAY FROM billing_month) = 1", name: "stripe_recurrence_charges_billing_month_first_day"
      t.check_constraint "billing_date >= billing_month AND billing_date < (billing_month + INTERVAL '1 month')", name: "stripe_recurrence_charges_billing_date_in_month"
      t.check_constraint "amount > 0", name: "stripe_recurrence_charges_amount_positive"
      t.check_constraint "application_fee_amount >= 0", name: "stripe_recurrence_charges_application_fee_amount_not_negative"
      t.check_constraint "attempt > 0", name: "stripe_recurrence_charges_attempt_positive"
      t.check_constraint "status IN ('pending', 'succeeded', 'processing', 'requires_action', 'declined', 'failed', 'canceled', 'skipped')", name: "stripe_recurrence_charges_status_known"
      t.check_constraint "status NOT IN ('succeeded', 'processing', 'requires_action', 'declined', 'canceled') OR stripe_payment_intent_id IS NOT NULL", name: "stripe_recurrence_charges_payment_intent_once_confirmed"
      t.check_constraint "(status = 'skipped') = (skip_reason IS NOT NULL)", name: "stripe_recurrence_charges_skip_reason_when_skipped"
    end
  end
end
