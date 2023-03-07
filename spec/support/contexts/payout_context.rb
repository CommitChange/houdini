# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE

shared_examples 'payout can create object event with publish_created' do
  let(:instance) { subject }

  it {
    initial_count = ObjectEvent.all.count
    instance.publish_created
    expect(ObjectEvent.all.count).to eq(initial_count + 1)
    }
end
