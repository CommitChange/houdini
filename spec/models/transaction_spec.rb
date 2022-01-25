# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE
require 'rails_helper'

RSpec.describe Transaction, type: :model do
  it_behaves_like 'an houidable entity', :trx

  describe 'validation' do
    it {is_expected.to validate_presence_of(:supporter)}
  end

  describe 'houid is created' do
    subject { Transaction.create(supporter:create(:supporter))}
    it {is_expected.to have_attributes(houid: match_houid('trx'))}
  end
end
