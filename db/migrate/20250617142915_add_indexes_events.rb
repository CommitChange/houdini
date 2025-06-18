class AddIndexesEvents < ActiveRecord::Migration[7.1]
  def change
    add_index :tickets, [:event_id, :quantity, :checked_in],
              name: 'idx_tickets_event_metrics'

    add_index :payments, [:donation_id, :gross_amount],
              name: 'idx_payments_donations'

    add_index :tickets, [:payment_id, :event_id],
              name: 'idx_tickets_payments'

    add_index :payments, [:id, :gross_amount],
              name: 'idx_payments_gross_amount'
  end
end
