# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
class Users::SessionsController < Devise::SessionsController
	include ::Controllers::XFrame
	
	layout 'layouts/apified', only: :new
	
	after_action :prevent_framing
  
	def new
    @theme = 'minimal'
    super
  end

	def create
    @theme = 'minimal'

		respond_to do |format|
			format.json {  
				self.resource = warden.authenticate!(:scope => resource_name, :recall => "#{controller_path}#new")
				sign_in(resource_name, resource)
				render :status => 200, :json => { :status => "Success" }  
			}
		end  
	end  

	
	# post /users/confirm_auth
	# A simple action to confirm an entered password for a user who is already signed in
	def confirm_auth
		if current_user.valid_password?(params[:password])
			tok = SecureRandom.uuid
			session[:pw_token]  = tok
			session[:pw_timestamp] = Time.current.to_s
			render json: {token: tok}, status: :ok
		else
			render json: ["Incorrect password. Please enter your #{Settings.general.name} password."], status: :unprocessable_entity
		end
  end
	
end

