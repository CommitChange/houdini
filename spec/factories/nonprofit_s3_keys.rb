FactoryBot.define do
  factory :nonprofit_s3_key do
    nonprofit { association :nonprofit_base}
    access_key_id { "MyString" }
    secret_access_key { "MyString" }
    bucket_name { "MyString" }
  end
end
