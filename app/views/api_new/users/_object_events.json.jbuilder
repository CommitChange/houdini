# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE

json.data do 
  json.array! object_events.map(&:object_json)
end

json.total_count object_events.total_count
