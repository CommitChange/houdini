class AddOffsitePaymentToOfflineTransactionCharge < ActiveRecord::Migration
  def change
    add_reference :offline_transaction_charges, :offsite_payment, index: true, foreign_key: true
  end
end
