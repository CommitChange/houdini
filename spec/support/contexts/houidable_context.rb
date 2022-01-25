# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE

shared_examples 'an houidable entity' do |prefix, attribute|

  let(:houid_attribute) { attribute || :houid }
  
  it {
    is_expected.to have_attributes(houid_prefix: prefix.to_sym)
  }

  it {
    is_expected.to have_attributes(houid_attribute: houid_attribute.to_sym)
  }
end