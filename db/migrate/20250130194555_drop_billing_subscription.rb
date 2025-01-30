class DropBillingSubscription < ActiveRecord::Migration
  def change
    drop_table :billing_subscriptions
  end
end
