# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
require 'rails_helper'

describe InsertBillingSubscriptions, :skip => true do

  let(:sub) do
    # billing_plan = Qx.insert_into(:billing_plans).values({name: 'test_bp', amount: 0, stripe_plan_id: 'stripe_bp', created_at: Time.current, updated_at: Time.current}).returning('*').execute.last
    # InsertBillingSubscriptions.trial(3624, billing_plan['stripe_plan_id'])[:json]
  end

  describe '.trial' do
    it 'creates the record' do
      sub
      expect(sub["id"]).to be_present
    end
  end
end
