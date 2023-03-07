# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE

shared_examples 'payout can create object event with publish_created' do
  let(:instance) { subject }

  it {
expect {  instance.publish_created }.to change { ObjectEvent.count }.by(1)
    }
end
