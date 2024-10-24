# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
FactoryBot.define do
  factory :event do
    name {"The event of Wonders"}
    start_datetime {DateTime.new(2025, 5, 11, 4,5,6)}
    end_datetime {DateTime.new(2025, 5, 11, 5,1,7)}
    address {"100 N Appleton St"}
    city {"Appleton"}
    state_code {"WI"}
    slug {"event-of-wonders"}
    nonprofit
    profile
  end

  factory :event_base, class: "Event" do
    sequence(:name){|i| "The event of Wonders #{i}"}
    start_datetime {DateTime.new(2025, 5, 11, 4,5,6)}
    end_datetime {DateTime.new(2025, 5, 11, 5,1,7)}
    address {"100 N Appleton St"}
    city {"Appleton"}
    state_code {"WI"}
    sequence(:slug){|i| "event-of-wonders-#{i}"}
    nonprofit {association :nonprofit_base}
    profile
  end
end
