
require 'rails_helper'
RSpec.describe BillingPlan, type: :model do
  
  context 'validation' do
    it {is_expected.to validate_presence_of(:amount)}
    it {is_expected.to validate_presence_of(:percentage_fee)}

    it {is_expected.to validate_numericality_of(:percentage_fee).is_less_than(1).is_greater_than_or_equal_to(0)}

    it{ is_expected.to validate_numericality_of(:flat_fee).is_greater_than_or_equal_to(0).only_integer}

    it {is_expected.to have_many(:billing_subscriptions)}
  end
  
  describe 'Caching' do
    describe '.create_cache_key' do
      it 'clears the proper key when id is an integer' do
        expect(described_class.create_cache_key(1)).to eq "billing_plan_nonprofit_id_1"
      end

      it 'clears the proper key when id is a nonprofit' do
        np = create(:nonprofit)
        expect(described_class.create_cache_key(np)).to eq "billing_plan_nonprofit_id_#{np.id}"
      end
    end
  end
end
