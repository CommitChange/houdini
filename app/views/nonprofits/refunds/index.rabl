# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
object false

child @refunds => :data do
	collection @refunds, object_root: false
	attributes :id, :amount, :created_at, :reason, :comment

end
