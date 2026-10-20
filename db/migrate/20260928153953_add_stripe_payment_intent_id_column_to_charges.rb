class AddStripePaymentIntentIdColumnToCharges < ActiveRecord::Migration[7.1]
  def change
    change_table :charges do |t|
      t.references :stripe_payment_intent, type: :string, null: true, foreign_key: true, comment: "the StripePaymentIntent associated with this charge if using Slipflow"
    end
  end
end
