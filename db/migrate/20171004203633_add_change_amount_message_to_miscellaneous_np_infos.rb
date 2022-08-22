# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
class AddChangeAmountMessageToMiscellaneousNpInfos < ActiveRecord::Migration
  def change
    add_column :miscellaneous_np_infos, :change_amount_message, :text
  end
end
