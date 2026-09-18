class NonprofitVerificationProcessStatus < ApplicationRecord
  belongs_to :stripe_account, primary_key: :stripe_account_id
end
