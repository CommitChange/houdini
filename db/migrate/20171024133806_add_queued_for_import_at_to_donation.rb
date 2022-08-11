# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
class AddQueuedForImportAtToDonation < ActiveRecord::Migration
  def change
    add_column :donations, :queued_for_import_at, :datetime, default: nil
  end
end
