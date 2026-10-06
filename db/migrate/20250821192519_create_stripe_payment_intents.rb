class CreateStripePaymentIntents < ActiveRecord::Migration[7.1]
  def change
    create_table :stripe_payment_intents, id: :string do |t|
      t.references :stripe_account, type: :string
      t.timestamps
    end
  end
end