# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
require 'rails_helper'

RSpec.describe Charge, :type => :model do

  it {is_expected.to belong_to(:card)}
  it {is_expected.to have_many(:stripe_dispute).with_primary_key(:stripe_charge_id).with_foreign_key(:stripe_charge_id)}
end
