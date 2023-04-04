# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
require 'qx'
require 'delayed_job_helper'
require 'active_support/core_ext'


module InsertBillingSubscriptions

  def self.trial(np_id, stripe_plan_id)
    begin
      nonprofit = Nonprofit.includes(:billing_subscription).find(np_id)
      billing_plan = BillingPlan.where('stripe_plan_id = ?', stripe_plan_id).last
      sub = nonprofit.create_billing_subscription(billing_plan: billing_plan, status: 'trialing')
      n = 10
      return {json: sub}
    rescue ActiveRecord::RecordNotFound => e
      return {json: { error: e }, status: :unprocessable_entity}
    end

  end

end
