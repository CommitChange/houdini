# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE

json.(supporter, :name, :organization, :phone, :anonymous, :deleted)

json.id supporter.houid

json.object 'supporter'

json.merged_into supporter.merged_into&.houid

json.supporter_addresses [supporter] do |supp|
  json.address supp.address
  json.city supp.city
  json.state_code supp.state_code
  json.zip_code supp.zip_code
  json.country supp.country
end

#json.url api_new_nonprofit_supporter_url(supporter.nonprofit, supporter.to_modern_param)

json.nonprofit supporter.nonprofit.id
