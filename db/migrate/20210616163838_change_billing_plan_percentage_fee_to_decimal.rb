class ChangeBillingPlanPercentageFeeToDecimal < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do 
        change_column :billing_plans, :percentage_fee, :decimal
      end

      dir.down do
        change_column :billing_plans, :percentage_fee, :float
      end
    end
  end
end
