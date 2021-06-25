class CreateFeeCoverageDetails < ActiveRecord::Migration
  def change
    create_table :fee_coverage_details do |t|
      t.integer :flat_fee
      t.decimal :percentage_fee
      t.references :fee_era

      t.timestamps null: false
    end
  end
end
