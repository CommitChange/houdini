FactoryBot.define do
  factory :supporter_address do
    address {"That street right there"}
    city {"Appleton"}
    zip_code {"71707273"}
    state_code {"WI"}
    country {"United States"}
    supporter nil
  end

  factory :other_supporter_address, class: SupporterAddress do
    address {"Clear Waters Park Avenue"}
    city {"Aguas Claras"}
    zip_code {"71707277"}
    state_code {"DF"}
    country {"Brazil"}
    supporter nil
  end
end
