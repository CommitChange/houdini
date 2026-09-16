# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
Rails.application.config.after_initialize do
  Mailchimp.config({
    api_key: ENV["MAILCHIMP_API_KEY"],
    username: ENV["MAILCHIMP_USERNAME"]
  })
end
