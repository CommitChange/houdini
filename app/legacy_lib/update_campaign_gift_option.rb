# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
module UpdateCampaignGiftOption

	def self.update gift_option, params
		gift_option.update_attributes params
		return gift_option
	end

end

