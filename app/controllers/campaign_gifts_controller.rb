# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
class CampaignGiftsController < ApplicationController

  # post /campaign_gifts
	def create
		json_saved CreateCampaignGift.create params[:campaign_gift]
	end
end
