# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
class RemoveArticles < ActiveRecord::Migration
  def up
    drop_table :articles
  end

  def down
  end
end
