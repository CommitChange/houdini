FactoryBot.define do
  factory :manual_balance_adjustment do
    fee_total { -100 }
    gross_amount { 0 }
  end
end
