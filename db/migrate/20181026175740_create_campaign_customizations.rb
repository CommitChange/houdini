# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
class CreateCampaignCustomizations < ActiveRecord::Migration
  def change
    add_column :campaigns, :goal_is_in_supporters, :boolean
    add_column :campaigns, :starting_point, :integer
  end
end
