# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE

module ApiNew
	# A controller for interacting with a nonprofit's supporters
	class ObjectEventsController < ApiNew::ApiController
		include Controllers::ApiNew::Nonprofit::Current
		include Controllers::Nonprofit::Authorization
		before_action :authenticate_nonprofit_user!

		# Gets the nonprofits supporters
		# If not logged in, causes a 401 error
		def index
			@object_events = current_nonprofit
				.associated_object_events.query(params.slice(:event_entity, :event_types))
				.order('created_at DESC').page(params[:page]).per(params[:per])
		end
	end
end
