# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
module CreateCampaignGift
	# @param  donation [Donation] 
	# @param  campaign_gift_option [CampaignGiftOption] 
	def self.create(donation, campaign_gift_option)
		begin
			return donation.campaign_gifts.create!(campaign_gift_option: campaign_gift_option)
		rescue => e
			#does donation already have a campaign_gift
			if e.record.errors[:donation].include? I18n.t('campaign_gifts.errors.donation_already_has_a_campaign_gift')
				raise ParamValidation::ValidationError.new("#{donation.id} already has at least one associated campaign gift", :key => :donation_id)
			end

			if e.record.errors[:donation].include? I18n.t('campaign_gifts.errors.needs_a_campaign_gift_option_from_the_same_campaign')
				raise ParamValidation::ValidationError.new("#{campaign_gift_option.id} is not for the same campaign as donation #{donation.id}", {:key => :campaign_gift_option_id})
			end
			
			if e.record.errors[:donation].include? I18n.t('campaign_gifts.errors.needs_to_be_a_recurring_gift_of_at_least', amount: campaign_gift_option.amount_recurring)
				AdminMailer.delay.notify_failed_gift(donation, donation.payments.first, campaign_gift_option)
				raise ParamValidation::ValidationError.new("#{campaign_gift_option.id} gift options requires a recurring donation of #{campaign_gift_option.amount_recurring} for donation #{donation.id}", {:key => :campaign_gift_option_id})
			end

			if e.record.errors[:donation].include? I18n.t('campaign_gifts.errors.needs_to_be_a_one_time_gift_of_at_least', amount: campaign_gift_option.amount_one_time)
				AdminMailer.delay.notify_failed_gift(donation,donation.payments.first, campaign_gift_option)
				raise ParamValidation::ValidationError.new("#{campaign_gift_option.id} gift options requires a donation of #{campaign_gift_option.amount_one_time} for donation #{donation.id}", {:key => :campaign_gift_option_id})
			end

			if e.record.errors[:campaign_gift_option].include? I18n.t('campaign_gifts.errors.campaign_gift_option_does_not_have_any_available_campaign_gifts')
				AdminMailer.delay.notify_failed_gift(donation,donation.payments.first, campaign_gift_option)
				raise ParamValidation::ValidationError.new("#{campaign_gift_option.id} has no more inventory", {:key => :campaign_gift_option_id})
			end
		end

	end

	def self.validate_campaign_gift(cg)
		donation = cg.donation
		campaign_gift_option = cg.campaign_gift_option
		if ((donation.recurring_donation != nil) && (campaign_gift_option.amount_recurring != nil && campaign_gift_option.amount_recurring > 0))
			# it's a recurring_donation. Is it enough? for the gift level?
			unless donation.recurring_donation.amount == (campaign_gift_option.amount_recurring)
				raise ParamValidation::ValidationError.new("#{campaign_gift_option.id} gift options requires a recurring donation of at least #{campaign_gift_option.amount_recurring}", {:key => :campaign_gift_option_id})
			end
		else
			unless donation.amount == (campaign_gift_option.amount_one_time)
				raise ParamValidation::ValidationError.new("#{campaign_gift_option.id} gift options requires a donation of at least #{campaign_gift_option.amount_one_time}", {:key => :campaign_gift_option_id})
			end
		end
	end


	def self.create_from_ids(params)
		begin
			donation = Donation.find(params[:donation_id])
		rescue
			raise ParamValidation::ValidationError.new("#{params[:donation_id]} is not a valid donation id.", {:key => :donation_id})
		end

		begin
			campaign_gift_option = CampaignGiftOption.find(params[:campaign_gift_option_id])
		rescue
			raise ParamValidation::ValidationError.new("#{params[:campaign_gift_option_id]} is not a valid campaign gift option", {:key => :campaign_gift_option_id})
		end

		CreateCampaignGift.create(donation, campaign_gift_option)
	end

end
