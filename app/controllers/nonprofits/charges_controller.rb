# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
module Nonprofits
	class ChargesController < ApplicationController
		include Controllers::NonprofitHelper

		before_action :authenticate_nonprofit_user!, only: :index

		# get /nonprofit/:nonprofit_id/charges
		def index
			redirect_to controller: :payments, action: :index
		end # def index

	end
end
