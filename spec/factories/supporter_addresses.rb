FactoryBot.define do
  factory :supporter_address do
    address {"That street right there"}
    city {"Appleton"}
    zip_code {"71707273"}
    state_code {"WI"}
    country {"United States"}
    supporter nil
  end
end
