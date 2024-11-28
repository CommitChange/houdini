# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
class Nonprofits::WidgetsController < ApplicationController
  include Controllers::NonprofitHelper


  def show
    unless params[:type] == 'campaign_thermometer' && current_nonprofit.campaigns.find(params[:campaign_id])
      render status: :bad_request
    end
  end
end
