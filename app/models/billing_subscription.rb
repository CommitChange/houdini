# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
class BillingSubscription < ActiveRecord::Base

	attr_accessible \
		:nonprofit_id, :nonprofit,
		:billing_plan_id, :billing_plan,
		:stripe_subscription_id,
		:status # trialing, active, past_due, canceled, or unpaid

	attr_accessor :stripe_plan_id, :manual
	belongs_to :nonprofit
	belongs_to :billing_plan

	validates :nonprofit, presence: true
	validates :billing_plan, presence: true

	after_save do
		nonprofit.clear_cache
		return true
	end

	def as_json(options={})
		h = super(options)
		h[:plan_name] = self.billing_plan.name
		h[:plan_amount] = self.billing_plan.amount / 100
		h
	end

	def self.create_with_stripe(np, params)
		bp = BillingPlan.find_by_stripe_plan_id params[:stripe_plan_id]
		h =  ConstructBillingSubscription.with_stripe np, bp
		return np.create_billing_subscription h
	end

	def self.clear_cache(np)
		Rails.cache.delete(BillingSubscription.create_cache_key(np))
	end

	def self.find_via_cached_np_id(np)
		np = np.id if np.is_a? Nonprofit
		key = BillingSubscription.create_cache_key(np)
		Rails.cache.fetch(key, expires_in: 4.hours) do
			Qx.fetch(:billing_subscriptions, {nonprofit_id: np}).last
		end
	  end

	def self.create_cache_key(np)
		np = np.id if np.is_a? Nonprofit
		"billing_subscription_nonprofit_id_#{np}"
	end

end

