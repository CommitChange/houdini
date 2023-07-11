FactoryBot.define do
  factory :drip_email_list do
  end

  factory :drip_email_list_base, class: 'DripEmailList' do 
    sequence(:list_name) {|i|"list_name#{i}"}
    sequence(:mailchimp_list_id) {|i| "mailchimp_list_id#{i}"}
  end 
end
