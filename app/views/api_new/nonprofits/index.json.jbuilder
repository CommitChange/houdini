# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE
json.data @nonprofits, partial: '/api_new/nonprofits/nonprofit', as: :nonprofit

json.current_page @nonprofits.current_page
json.first_page @nonprofits.first_page?
json.last_page @nonprofits.last_page?
json.requested_size @nonprofits.limit_value
json.total_count @nonprofits.total_count
