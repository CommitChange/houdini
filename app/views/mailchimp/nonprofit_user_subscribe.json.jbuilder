# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later 

json.email_address @user.email
json.status 'subscribed'

json.merge_fields do
  json.nonprofit_id  @user.nonprofit
end 