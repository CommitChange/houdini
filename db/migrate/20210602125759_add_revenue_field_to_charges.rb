class AddRevenueFieldToCharges < ActiveRecord::Migration
  def change
    add_column :charges, :revenue, :string, :default => nil
  end
end
