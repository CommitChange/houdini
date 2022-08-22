# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
class AddIndexToCampaignGifts < ActiveRecord::Migration
  def change
    add_index :campaign_gifts, :campaign_gift_option_id
  end
end
