# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
object false

child @campaigns => :data do
	collection @campaigns, object_root: false
	attributes :name, :total_raised, :goal_amount, :url, :id
end

