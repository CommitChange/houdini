# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
require "rails_helper"
RSpec.describe Activity, type: :model do
  context "validation" do
    it { is_expected.to belong_to(:attachment).required(true) }
    it { is_expected.to belong_to(:supporter).required(true) }

    it { is_expected.to belong_to(:nonprofit).required(true) }

    it { is_expected.to belong_to(:user).required(false) }

  end
end
