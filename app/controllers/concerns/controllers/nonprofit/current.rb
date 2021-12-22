# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE
module Controllers::Nonprofit::Current
	extend ActiveSupport::Concern
	included do
		private

		def current_nonprofit
			Nonprofit.find_by(houid:params[:nonprofit_id])
		end

		def current_nonprofit_without_exception
			begin
				current_nonprofit
			rescue
				false
			end
		end
	end
end
