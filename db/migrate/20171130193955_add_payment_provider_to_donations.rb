# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
class AddPaymentProviderToDonations < ActiveRecord::Migration
  def change
    add_column :donations, :payment_provider, :string
  end
end
