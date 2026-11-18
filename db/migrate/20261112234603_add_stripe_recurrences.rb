class AddStripeRecurrences < ActiveRecord::Migration[7.1]
  def change
    create_table :stripe_recurrences do |t|
      t.integer :amount, null: false
      t.datetime :start_time, null:false, comment: "When the schedule began. Charges will happen monthly going forward." 
      t.references :payment_intent, comment: "The general PaymentIntent belonging to a nonprofit that created this recurrence"
      t.references :stripe_payment_intent, comment: "The local copy of the Stripe::PaymentIntent that created this recurrence", type: :string
      t.references :stripe_account, comment: "The id of the StripeAccount used that this is associated with"
      t.string :stripe_customer_id, null: false, comment: "The id of a Stripe::Customer to use for future payment"
      t.string :stripe_payment_method_id, null: false, comment: "The id of the Stripe::PaymentMethod to use for future payments"
      t.timestamps
    end
  end
end
