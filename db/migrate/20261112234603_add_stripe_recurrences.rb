class AddStripeRecurrences < ActiveRecord::Migration[7.1]
  def change
    create_table :stripe_recurrences do |t|
      t.integer :gift_amount, null: false, comment: "The gift each month, in cents, without any fee the donor covers"
      t.boolean :fee_covered, null: false, default: false, comment: "Whether the donor chose to cover the fee"
      t.integer :covered_fee_amount, null: false, default: 0, comment: "The fee the donor covers each month, in cents; 0 when they don't"
      t.datetime :start_time, null: false, comment: "When the schedule began. Charges will happen monthly going forward."
      t.references :payment_intent, null: false, foreign_key: true, index: {unique: true}, comment: "The general PaymentIntent belonging to a nonprofit that created this recurrence"
      t.references :stripe_payment_intent, null: false, foreign_key: true, index: {unique: true}, comment: "The local copy of the Stripe::PaymentIntent that created this recurrence", type: :string
      t.references :stripe_account, null: false, foreign_key: true, comment: "The StripeAccount (its id, not its acct_ id) the recurrence's payments go to"
      t.string :stripe_customer_id, null: false, comment: "The id of a Stripe::Customer, on the platform account, to use for future payment"
      t.string :stripe_payment_method_id, null: false, comment: "The id of the Stripe::PaymentMethod to use for future payments"
      t.timestamps
      t.check_constraint "gift_amount > 0", name: "stripe_recurrences_gift_amount_positive"
      t.check_constraint "covered_fee_amount >= 0", name: "stripe_recurrences_covered_fee_amount_not_negative"
      t.check_constraint "fee_covered OR covered_fee_amount = 0", name: "stripe_recurrences_covered_fee_amount_only_when_covered"
    end
  end
end
