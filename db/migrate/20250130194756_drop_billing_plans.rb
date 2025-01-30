class DropBillingPlans < ActiveRecord::Migration
  def change
    drop_table :billing_plans
  end
end
