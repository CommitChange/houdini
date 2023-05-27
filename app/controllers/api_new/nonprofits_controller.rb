# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE

module ApiNew
	# A controller for getting all nonprofits
	class NonprofitsController < ApiNew::ApiController
		before_action :authenticate_user!
    
    has_scope :has_at_least_associate_access, type: :boolean do |controller, scope|
      scope.has_at_least_associate_access(controller.current_user)
    end

		# Gets the nonprofits
		# If not logged in, causes a 401 error
		def index
			@nonprofits = apply_scopes(Nonprofit).order('id DESC').page(params[:page]).per(params[:per])
    end
	end
end
