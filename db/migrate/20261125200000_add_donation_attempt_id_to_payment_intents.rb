class AddDonationAttemptIdToPaymentIntents < ActiveRecord::Migration[7.1]
  def change
    add_column :payment_intents, :donation_attempt_id, :uuid, comment: "The donate page's id for one donation, the same across its retries; null for PaymentIntents made before it"
    add_index :payment_intents, [:nonprofit_id, :donation_attempt_id], unique: true
  end
end
