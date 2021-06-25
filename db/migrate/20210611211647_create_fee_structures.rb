class CreateFeeStructures < ActiveRecord::Migration
  def change
    create_table :fee_structures do |t|
      t.string :brand
      t.integer :flat_fee
      t.decimal :stripe_fee
      t.references :fee_era, required: true

      t.timestamps null: false
    end
  end
end
