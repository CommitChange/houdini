require 'rails_helper'

RSpec.describe FeeCoverageDetail, type: :model do
  context 'validation' do
    it {is_expected.to have_one(:fee_era).validate(true)}
  end
end
