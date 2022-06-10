# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE
require 'rails_helper'

RSpec.describe OfflineTransaction, type: :model do
	it_behaves_like 'subtransactable', :offlinetrx, :offline_transaction_for_testing_payment_extensions
end