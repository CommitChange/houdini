class NonprofitVerificationProcessStatus < ActiveRecord::Base
  attr_accessible :started_at, :stripe_account_id

  belongs_to :stripe_account, foreign_key: :stripe_account_id

end
