# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
FactoryBot.define do
  factory :user, aliases: [:user_base] do
    sequence(:email) {|i| "user#{i}@example.string.com"}
    password {"whocares"}
    
    factory :user_as_nonprofit_admin  do
      transient do
        nonprofit { association :nonprofit_base }
      end

      roles {[
        association(:role, name: 'nonprofit_admin', host: nonprofit)
      ]}

    end
    
    
  end

  factory :automated_user, class: User do 
    email { "automated_user@automated_user.user"}
    password {"whocares"}
    id { 540 }
  end

  factory :user_as_nonprofit_associate, class: User do
    transient do
      nonprofit { create(:nonprofit_base) }
    end

    sequence(:email) {|i| "user#{i}@example.string.com"}
    password {"whocares"}
    roles {[
      build(:role, name: 'nonprofit_associate', host: nonprofit)
    ]}
  end

  factory :user_as_super_admin, class: User do
    transient do
      nonprofit { create(:nonprofit_base) }
    end
    sequence(:email) {|i| "user#{i}@example.string.com"}
    password {"whocares"}
    roles {[
      build(:role, name: 'nonprofit_associate', host: create(:nonprofit_base)),
      build(:role, name: 'super_admin')
    ]}
  end

  trait :and_sign_in_ip do
    last_sign_in_ip { "1.1.1.1"}
  end
end
