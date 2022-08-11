# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
class IndexCardsOnHolderIdAndHolderType < ActiveRecord::Migration
  def change
    add_index :cards, [:holder_id, :holder_type]
  end
end
