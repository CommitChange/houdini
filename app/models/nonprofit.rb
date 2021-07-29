# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
class Nonprofit < ActiveRecord::Base

  Categories = ["Public Benefit", "Human Services", "Education", "Civic Duty", "Human Rights", "Animals", "Environment", "Health", "Arts, Culture, Humanities", "International", "Children", "Religion", "LGBTQ", "Women's Rights", "Disaster Relief", "Veterans"]

  attr_accessible \
    :name, # str
    :stripe_account_id, # str
    :summary, # text: paragraph-sized organization summary
    :tagline, # str
    :email, # str: public organization contact email
    :phone, # str: public org contact phone
    :main_image, # str: url of featured image - first image in profile carousel
    :second_image, # str: url of 2nd image in carousel
    :third_image, # str: url of 3rd image in carousel
    :background_image,  # str: url of large profile background
    :remove_background_image, #bool carrierwave
    :logo, # str: small logo image url for searching
    :zip_code, # int
    :website, # str: their own website url
    :categories, # text [str]: see the constant Categories
    :achievements, # text [str]: highlights about this org
    :full_description, # text
    :state_code, # str: two-letter state code (eg. CA)
    :statement, # str: bank statement for donations towards the nonprofit
    :city, # str
    :slug, # str
    :city_slug, #str
    :state_code_slug, #str
    :ein, # str: employee identification number
    :published, # boolean; whether to display this profile
    :vetted, # bool: Whether a super admin (one of CommitChange's employees) have approved this org
    :verification_status, # str (either 'pending', 'unverified', 'escalated', 'verified' -- whether the org has submitted the identity verification form and it has been approved)
    :latitude, # float: geocoder gem
    :longitude, # float: geocoder gem
    :timezone, # str
    :address, # text
    :thank_you_note, # text
    :referrer, # str
    :no_anon, # bool: whether to allow anonymous donations
    :roles_attributes,
    :brand_font, #string (lowercase key eg. 'helvetica')
    :brand_color, #string (hex color value)
    :hide_activity_feed, # bool
    :tracking_script,
    :facebook, #string (url)
    :twitter, #string (url)
    :youtube, #string (url)
    :instagram, #string (url)
    :blog, #string (url)
    :card_failure_message_top, # text
    :card_failure_message_bottom, # text
    :autocomplete_supporter_address # boolean

  has_many :payouts
  has_many :charges
  has_many :refunds, through: :charges
  has_many :donations
  has_many :recurring_donations
  has_many :payments
  has_many :supporters, dependent: :destroy
  has_many :supporter_notes, through: :supporters
  has_many :profiles, through: :donations
  has_many :campaigns, dependent: :destroy
  has_many :events, dependent: :destroy
  has_many :tickets, through: :events
  has_many :users, through: :roles
  has_many :tag_masters, dependent: :destroy
  has_many :custom_field_masters, dependent: :destroy
  has_many :roles,        as: :host, dependent: :destroy
  has_many :activities,   as: :host, dependent: :destroy
  has_many :imports
  has_many :email_settings
  has_many :cards, as: :holder

  has_one :bank_account, -> { where("COALESCE(bank_accounts.deleted, false) = false") }, dependent: :destroy
  has_one :billing_subscription, dependent: :destroy
  has_one :billing_plan, through: :billing_subscription
  has_one :miscellaneous_np_info
  has_one :nonprofit_deactivation
  has_one :stripe_account, foreign_key: :stripe_account_id, primary_key: :stripe_account_id

  validates :name, presence: true
  validates :city, presence: true
  validates :state_code, presence: true
  validates :email, format: { with: Email::Regex }, allow_blank: true
  validate :timezone_is_valid
  validates_uniqueness_of :slug, scope: [:city_slug, :state_code_slug]
  validates_presence_of :slug

  scope :vetted, -> {where(vetted: true)}
  scope :published, -> {where(published: true)}

  mount_uploader :main_image, NonprofitUploader
  mount_uploader :second_image, NonprofitUploader
  mount_uploader :third_image, NonprofitUploader
  mount_uploader :background_image, NonprofitBackgroundUploader
  mount_uploader :logo, NonprofitLogoUploader

  serialize :achievements, Array
  serialize :categories, Array

  geocoded_by :full_address


  scope :activated, -> { includes(:nonprofit_deactivation).where('nonprofit_deactivations.nonprofit_id IS NULL OR NOT COALESCE(nonprofit_deactivations.deactivated, false)').references(:nonprofit_deactivations)}
  scope :deactivated, -> { joins(:nonprofit_deactivation).where('nonprofit_deactivations.deactivated = true')}

  before_validation(on: :create) do
    self.set_slugs
    self
  end

  after_save do
    self.clear_cache
    self
  end

  # Register (create) a nonprofit with an initial admin
  def self.register(user, params)
    np = self.create ConstructNonprofit.construct(user, params)
    role = Role.create(user: user, name: 'nonprofit_admin', host: np) if np.valid?
    return np
  end


  def nonprofit_personnel_emails
    self.roles.nonprofit_personnel.joins(:user).pluck('users.email')
  end

  def total_recurring
    recurring_donations.active.sum(:amount)
  end

  def donation_history_monthly
    donation_history_monthly = []
    donations.order("created_at")
      .group_by{|d| d.created_at.beginning_of_month}
      .each{|_, ds| donation_history_monthly.push(ds.map(&:amount).sum)}
    donation_history_monthly
  end

  def as_json(options = {})
    h = super(options)
    h[:url] = self.url
    h
  end

  def url
    "/#{self.state_code_slug}/#{self.city_slug}/#{self.slug}"
  end

  def set_slugs
    unless (self.slug)
      self.slug = Format::Url.convert_to_slug self.name
    end
    unless (self.city_slug)
      self.city_slug = Format::Url.convert_to_slug self.city
    end

    unless (self.state_code_slug)
      self.state_code_slug = Format::Url.convert_to_slug self.state_code
    end
    self
  end

  def full_address
    Format::Address.full_address(self.address, self.city, self.state_code)
  end

  def total_raised
    QueryPayments.get_payout_totals( QueryPayments.ids_for_payout(self.id))['net_amount']
  end

  def can_make_payouts?
    !!(vetted && bank_account && 
    !bank_account.deleted &&
    !bank_account.pending_verification && 
    stripe_account&.payouts_enabled && 
    !(nonprofit_deactivation&.deactivated))
  end

  def active_cards
    cards.where("COALESCE(cards.inactive, FALSE) = FALSE")
  end

  # @param [Card] card the new active_card
  def active_card=(card)
    unless card.class == Card
      raise ArgumentError.new "Pass a card to active_card or else"
    end
    Card.transaction do
      active_cards.update_all :inactive => true
      return cards << card
    end
  end

  def active_card
    active_cards.first
  end

  def create_active_card(card_data)
    if (card_data[:inactive])
      raise ArgumentError.new "This method is for creating active cards only"
    end
    active_cards.update_all :inactive => true
    return cards.create(card_data)
  end

  def currency_symbol
    Settings.intntl.all_currencies.find{|i| i.abbv.downcase == currency.downcase}&.symbol
  end

  def steps_to_payout
    ret = []
    
    ret.push({name: :verification, 
      status: stripe_account&.verification_status || 
        :unverified})

    bank_status = nil
    no_bank_account = !bank_account || bank_account.deleted

    pending_bank_account = bank_account&.pending_verification

    valid_bank_account = bank_account && bank_account.pending_verification

    if (no_bank_account)
      bank_status= :no_bank_account
    elsif(pending_bank_account)
      bank_status=:pending_bank_account
    else
      bank_status=:valid_bank_account
    end
    
    ret.push({name: :bank_account, status: bank_status})

    ret.push({
      name: :vetted, 
      status: vetted
    })
    ret
  end

  concerning :FeeCalculation do
    
    # @param [Hash] opts
    # @option opts [#brand, #country] :source the source to use for calculating the fee
    # @option opts [Integer] :amount  the amount of the transaction in cents
    # @option opts [DateTime,nil] :at (nil) the time to use for searching for a FeeEra. Default of current time
    def calculate_fee(opts={})
      FeeEra.calculate_fee(
        **opts,
        platform_fee: billing_plan.percentage_fee.to_s,
        flat_fee: billing_plan.flat_fee
        )
    end


    # @param [Hash] opts
    # @option opts [#brand, #country] :source  the source to use for calculating the fee
    # @option opts [Integer] :amount  the amount of the transaction in cents
    # @option opts [DateTime,nil] :at (nil) the time to use for searching for a FeeEra. Default of current time
    def calculate_stripe_fee(opts={})
      FeeEra.calculate_stripe_fee(opts)
    end

    # @param [Hash] opts
    # @option opts [Time] :charge_date the date that the charge occurred for purposes of finding the correct fee era
    # @option opts [Stripe::Charge] :charge the Stripe::Charge to use for calculating the fee
    # @option opts [Stripe::Refund] :refund the Stripe::Refund for 
    # @option opts [Stripe::ApplicationFee] :application_fee the Stripe::ApplicationFee for this Charge
    def calculate_application_fee_refund(opts={})
      FeeEra.calculate_application_fee_refund(opts)
    end

    # the flat_fee and percentage_fee to use for calculating fee coverage on transactions for this nonprofit
    # 
    # These fee_coverage details are calcuated as follows:
    # 
    # {
    #   flat_fee: flat_fee as part of BillingPlan (unless FeeCoverageDetailsBase.dont_consider_billing_plan is true) + flat_fee from FeeCoverageDetailBase on current FeeEra,
    #   percentage_fee: percentage_fee as part of BillingPlan (unless FeeCoverageDetailsBase.dont_consider_billing_plan is true) + percentage_fee from FeeCoverageDetailBase on current FeeEra
    # }
    def fee_coverage_details
      {
        flat_fee: (FeeEra.current.fee_coverage_detail_base.dont_consider_billing_plan ? 0 : billing_plan.flat_fee) + FeeEra.current.fee_coverage_detail_base.flat_fee,
        percentage_fee: (FeeEra.current.fee_coverage_detail_base.dont_consider_billing_plan ? 0: billing_plan.percentage_fee) + FeeEra.current.fee_coverage_detail_base.percentage_fee
      }
    end

    def fee_coverage_details_with_json_safe_keys
      fee_coverage_details.transform_keys{|i| i.to_s.camelize(:lower)}
    end
  end

  def hide_cover_fees?
    miscellaneous_np_info&.hide_cover_fees
  end

  def clear_cache
    Nonprofit::clear_caching(id, state_code_slug, city_slug, slug)
  end

  def self.clear_caching(id, state_code, city, name)
    Rails.cache.delete(Nonprofit::create_cache_key_for_id(id))
    Rails.cache.delete(Nonprofit::create_cache_key_for_location(state_code, city, name))
    BillingSubscription.clear_cache(id)
    BillingPlan.clear_cache(id)
  end

  def self.find_via_cached_id(id)
    key = create_cache_key_for_id(id)
    Rails.cache.fetch(key, expires_in: 4.hours) do
      Nonprofit.find(id)
    end
  end

  def self.find_via_cached_key_for_location(state_code, city, name)
    key = create_cache_key_for_location(state_code, city, name)
    Rails.cache.fetch(key, expires_in: 4.hours) do
      Nonprofit.where(:state_code_slug => state_code, :city_slug => city, :slug => name).last
    end
  end

  def self.create_cache_key_for_id(id)
    "nonprofit__CACHE_KEY__ID___#{id}"
  end

  def self.create_cache_key_for_location(state_code,city, name)
    "nonprofit__CACHE_KEY__LOCATION___#{state_code}____#{city}___#{name}"
  end

  private

  def timezone_is_valid
    timezone.blank? || ActiveSupport::TimeZone.all.map{ |t| t.tzinfo.name }.include?(timezone) || errors.add(:timezone, 'is not a valid timezone')
  end
end
