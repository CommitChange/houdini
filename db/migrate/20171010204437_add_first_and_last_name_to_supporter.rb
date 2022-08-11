# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
class AddFirstAndLastNameToSupporter < ActiveRecord::Migration
  def change
    add_column :supporters, :first_name, :string
    add_column :supporters, :last_name, :string
  end
end
