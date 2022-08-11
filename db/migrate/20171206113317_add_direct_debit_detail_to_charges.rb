# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
class AddDirectDebitDetailToCharges < ActiveRecord::Migration
  def change
    add_column :charges, :direct_debit_detail_id, :integer
  end
end
