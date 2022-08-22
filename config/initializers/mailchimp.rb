# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
require 'mailchimp'

Mailchimp.config({
	:api_key => ENV['MAILCHIMP_API_KEY'],
	:username => ENV['MAILCHIMP_USERNAME']
})
