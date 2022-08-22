# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
class AddUtmContentToTrackings < ActiveRecord::Migration
  def change
    add_column :trackings, :utm_content, :string, unique: true
  end
end
