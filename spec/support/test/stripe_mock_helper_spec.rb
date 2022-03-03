# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
require 'rails_helper'

describe StripeMockHelper do  
  it 'sets stripe_helper' do
    expect(StripeMockHelper.stripe_helper).to be_falsy
    StripeMockHelper.mock do
      expect(StripeMockHelper.stripe_helper).to be_truthy
    end
  end

  it 'clears stripe_helper when finished' do
    StripeMockHelper.mock do
    end
    expect(StripeMockHelper.stripe_helper).to be_falsy
  end
end