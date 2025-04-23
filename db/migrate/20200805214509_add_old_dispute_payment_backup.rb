class AddOldDisputePaymentBackup < ActiveRecord::Migration
  def change
    # rubocop:disable Rails/CreateTableWithTimestamps
    create_table :dispute_payment_backups do |t|
      t.references :dispute
      t.references :payment
    end
    # rubocop:enable Rails/CreateTableWithTimestamps
  end
end
