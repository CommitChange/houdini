# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
module NonprofitPath

	def self.show(np)
    return "/" unless np
		"/#{np.state_code_slug}/#{np.city_slug}/#{np.slug}"
	end

	def self.dashboard(np)
		"#{show(np)}/dashboard"
	end
end
