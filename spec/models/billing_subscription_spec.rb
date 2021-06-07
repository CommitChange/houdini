
require 'rails_helper'
RSpec.describe BillingSubscription, type: :model do
  
  context 'validation' do
    it {is_expected.to validate_presence_of(:nonprofit)}
    it {is_expected.to validate_presence_of(:billing_plan)}

    it {is_expected.to belong_to(:nonprofit)}

    it{ is_expected.to belong_to(:billing_plan)}
  end
  
end
