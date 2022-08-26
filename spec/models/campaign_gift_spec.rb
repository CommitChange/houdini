# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
require 'rails_helper'

RSpec.describe CampaignGift, type: :model do
  it {is_expected.to belong_to(:donation)}
  it {is_expected.to validate_presence_of(:donation)}

  it {is_expected.to belong_to(:campaign_gift_option)}
  it {is_expected.to validate_presence_of(:campaign_gift_option)}

  
  it '#has_campaign_gift_option_availability' do
    donation = create(:donation_base_with_supporter)
    cgo = build(
      :campaign_gift_option,
      campaign: build(
        :campaign_with_things_set_1, nonprofit:donation.nonprofit
      ),
      quantity:1
    )

    expect(cgo).to receive(:gifts_available?).and_return(false)

    cg = CampaignGift.new(donation: donation, campaign_gift_option: cgo)

    expect(cg).to_not be_valid
    expect(cg.errors[:campaign_gift_option]).to include I18n.t('campaign_gifts.errors.campaign_gift_option_does_not_have_any_available_campaign_gifts')
  end

  it 'validates that the campaign_gift_option is the only one on the donation before saved' do
    donation = create(:donation_base_with_supporter, :and_campaign_gift)
    cg = CampaignGift.new(donation: donation, campaign_gift_option:build(:campaign_gift_option, campaign: donation.campaign))
    expect(cg).to_not be_valid
    expect(cg.errors[:donation]).to include I18n.t('campaign_gifts.errors.donation_already_has_a_campaign_gift')
  end

  it 'validates that the campaign_gift_option when updated is the only one on the donation on saved' do
    donation = create(:donation_base_with_supporter, :and_campaign_gift)
    cg = CampaignGift.create(donation: donation, campaign_gift_option:build(:campaign_gift_option, campaign: donation.campaign))
    cgo = force_create(
      :campaign_gift_option,
      campaign: build(
        :campaign_with_things_set_1, nonprofit:donation.nonprofit
      ),
      quantity:1
    )


    expect(cg).to_not be_valid
    expect(cg.errors[:donation]).to include I18n.t('campaign_gifts.errors.donation_already_has_a_campaign_gift')
  end

  it 'makes the campaign_gift_option valid when it is the only campaign_gift saved' do
    donation = create(:donation_base_with_supporter, :and_campaign_gift)
    cg = donation.campaign_gifts.first
    expect(cg).to be_valid
  end

  it 'validates that a one time donation has at least as much as the required one time amount' do
    donation = build(:donation_base_with_supporter)
    amount_one_time = donation.amount + 300
    cg = CampaignGift.new(donation:donation, campaign_gift_option:build(:campaign_gift_option, amount_one_time: amount_one_time))
    expect(cg).to_not be_valid
  end

  it 'validates that a recurring donation has at least as much as the required recurring amount' do
    donation = build(:donation_base_with_supporter, :and_recurring)
    amount_recurring = donation.amount + 300
    cg = CampaignGift.new(donation:donation, campaign_gift_option:build(:campaign_gift_option, amount_recurring: amount_recurring))

    expect(cg).to_not be_valid
    expect(cg.errors[:donation]).to include I18n.t('campaign_gifts.errors.needs_to_be_a_recurring_gift_of_at_least', amount: amount_recurring)
  end

  it 'validates that the campaign gift option and donation are for the same campaign' do
    donation = build(:donation_base_with_supporter)
    
    cg = CampaignGift.new(donation:donation, campaign_gift_option:build(:campaign_gift_option))

    expect(cg).to_not be_valid
    expect(cg.errors[:donation]).to include I18n.t('campaign_gifts.errors.needs_a_campaign_gift_option_from_the_same_campaign')
  end

  it 'allows the CampaignGiftOption for a one time donation' do
    donation = build(:donation_base_with_supporter, :and_campaign)
    amount_one_time = donation.amount
    cg = CampaignGift.new(donation:donation, campaign_gift_option:build(:campaign_gift_option, campaign:donation.campaign, amount_one_time: amount_one_time))

    expect(cg).to be_valid
    cg.save

    expect(cg).to be_persisted
  end

  it 'allows the CampaignGiftOption for a recurring donation' do
    donation = build(:donation_base_with_supporter, :and_recurring, :and_campaign)
    amount_recurring = donation.amount
    cg = CampaignGift.new(donation:donation, campaign_gift_option:build(:campaign_gift_option, campaign: donation.campaign, amount_recurring: amount_recurring))

    expect(cg).to be_valid
    cg.save

    expect(cg).to be_persisted
  end

  
  
end
