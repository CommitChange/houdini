# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE
require 'rails_helper'

RSpec.describe 'Widgets Routing', type: :routing do
  it "routes nonprofits/:nonprofit_id/widgets to Nonprofits::WidgetsController" do 
    expect(get('nonprofits/1/widgets')).to route_to(
      controller: "nonprofits/widgets",
      action: "show",
      nonprofit_id: "1"
    )
  end
end