# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later 
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE
require 'rails_helper'

Rspec.describe '/mailchimp/nonprofit_user_subscribe.json.jbuilder', type: :view do
  
  describe 'adding new subscriber to nonprofit list' do 

    subject(:json) do 
      # do I need this line specifically? If so, what is it doing?
      # where would i find these methods defined? In jbuilder docs? 
      # view.lookup_context.prefixes = view.lookup_context.prefixes.drop(1)
      assign(:user), create(:user, nonprofit_id: '123456')
    end 

    it {
      is_expected.to include_json(
        email_address: User.email.,
        status: 'subscribed',
        merge_fields: {
          nonprofit_id: '123456'
        }
      )
    }
  end 

  # Does this need to be skipped like in list.json.jbuilder.spec?
  describe 'not adding new subscriber to nonprofit list', skip: 'TODO' do 
  end 

end 

