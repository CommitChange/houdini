# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
class AddIndexToActivities < ActiveRecord::Migration
  def change
    add_index :activities, :supporter_id
    add_index :activities, :nonprofit_id
  end
end
