# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
FactoryBot.define do
  factory :supporter_expectation, class: "OpenStruct" do

    id { match_houid(:supp) }
    deleted {false}
    object {'supporter'}


  end
end