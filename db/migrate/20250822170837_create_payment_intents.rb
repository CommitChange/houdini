class CreatePaymentIntents < ActiveRecord::Migration[7.1]
  def change
    create_table :payment_intents do |t|
      t.references :nonprofit, null: false
      t.references :stripe_payment_intent, type: :string
      t.timestamps
    end
  end
end