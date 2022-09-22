FactoryBot.define do
  factory :manual_balance_adjustment do
    fee_total { -100 }
    gross_amount { 0 }

    trait :with_entity_and_payment do
      entity {create(:charge_base)}
      payment { build(:payment, gross_amount: gross_amount, fee_total: fee_total, net_amount: fee_total + gross_amount, 
        supporter: entity.supporter, nonprofit: entity.nonprofit, date: Time.current)}
    end
  end
end
