# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE
require 'rails_helper'

RSpec.describe ManualBalanceAdjustment, type: :model do
  it {is_expected.to belong_to(:entity).required(true)}
  it {is_expected.to belong_to(:payment).required(true)}
  it {is_expected.to have_one(:supporter).through(:payment)}
  it {is_expected.to have_one(:nonprofit).through(:payment)}
  it {is_expected.to validate_presence_of(:gross_amount)}
  it {is_expected.to validate_presence_of(:fee_total)}
  it {is_expected.to validate_presence_of(:net_amount)}
end
