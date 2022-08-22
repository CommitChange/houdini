# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
class AddChargesPaymentIdIndex < ActiveRecord::Migration
  def change
    add_index :charges, :payment_id
  end
end
