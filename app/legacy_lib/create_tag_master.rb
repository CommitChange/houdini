# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
module CreateTagMaster

	def self.create(nonprofit, params)
		tag_master = nonprofit.tag_masters.create(params)
		return tag_master
	end
end

