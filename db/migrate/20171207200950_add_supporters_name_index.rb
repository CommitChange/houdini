# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
class AddSupportersNameIndex < ActiveRecord::Migration
  def change
    add_index :supporters, :name
  end
end
