# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
class CampaignGift < ActiveRecord::Base

	attr_accessible \
		:donation_id,
		:donation,
		:campaign_gift_option,
		:campaign_gift_option_id

	belongs_to :donation
	belongs_to :campaign_gift_option

	validates :donation, presence: true
	validates :campaign_gift_option, presence: true

	validate :has_campaign_gift_option_availability,
		:donation_already_has_gift_option_set,
		:donation_amount_is_enough,
		:donation_and_campaign_gift_option_from_same_campaign
		
	

	private
	def has_campaign_gift_option_availability
		unless campaign_gift_option&.gifts_available?
			errors.add(:campaign_gift_option, I18n.t('campaign_gifts.errors.campaign_gift_option_does_not_have_any_available_campaign_gifts'))
		end
	end

	def donation_already_has_gift_option_set
		if donation && donation.campaign_gifts.count > 0 && (!persisted?  || (persisted? && donation.campaign_gifts.first != self))
			errors.add(:donation, I18n.t('campaign_gifts.errors.donation_already_has_a_campaign_gift'))
		end
	end

	def donation_amount_is_enough
		if donation && campaign_gift_option
			if ((donation.recurring_donation != nil) && (campaign_gift_option.amount_recurring != nil && campaign_gift_option.amount_recurring > 0))
				# it's a recurring_donation. Is it enough? for the gift level?
				if donation.recurring_donation.amount < campaign_gift_option.amount_recurring # || (donation.recurring_donation.amount - CalculateFees.for_single_amount(donation.recurring_donation.amount, billing_plan.percentage_fee) == campaign_gift_option.amount_recurring)
					errors.add(:donation, I18n.t('campaign_gifts.errors.needs_to_be_a_recurring_gift_of_at_least', amount: campaign_gift_option.amount_recurring))
				end
			else
				if donation&.amount && donation.amount < (campaign_gift_option.amount_one_time) # || (donation.amount - CalculateFees.for_single_amount(donation.amount, billing_plan.percentage_fee) == campaign_gift_option.amount_one_time)
					errors.add(:donation, I18n.t('campaign_gifts.errors.needs_to_be_a_one_time_gift_of_at_least', amount: campaign_gift_option.amount_one_time))
				end
			end
		end
	end

	def donation_and_campaign_gift_option_from_same_campaign
		if donation&.campaign != campaign_gift_option&.campaign
			errors.add(:donation, I18n.t('campaign_gifts.errors.needs_a_campaign_gift_option_from_the_same_campaign'))
		end
	end
end
