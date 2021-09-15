# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
class CardsController < ApplicationController

	before_action :authenticate_user!, :except => [:create]
  before_action :verify_via_recaptcha!, only: [:create]

  rescue_from ::Recaptcha::RecaptchaError, with: :handle_recaptcha_failure

	# post /cards
  def create
    render(
      JsonResp.new(params) do |d|
        requires(:card).nested do
          requires(:name, :stripe_card_token).as_string
          requires(:holder_id).as_int
          requires(:holder_type).one_of('Supporter')
        end
      end.when_valid do |d|
        supporter = Supporter.find(d[:card][:holder_id])
        acct = supporter.nonprofit.stripe_account_id
        InsertCard.with_stripe(d[:card], acct,  params[:event_id], current_user)
      end
    )
	end

  private
  def verify_via_recaptcha!
    begin
      verify_recaptcha!(action: 'create_card', minimum_score: ENV['MINIMUM_RECAPTCHA_SCORE'].to_f)
    rescue ::Recaptcha::RecaptchaError => e
      supporter_id = params.try(:card).try(:holder_id)
      failure_details = {
        supporter: supporter_id,
        params: params,
        action: 'create_card',
        minimum_score_required: ENV['MINIMUM_RECAPTCHA_SCORE'],
        recaptcha_result: recaptcha_reply,
        recaptcha_value: d['g-recaptcha-response']
      }
      failure = RecaptchaRejection.new
      failure.details_json = failure_details
      failure.save!
      raise e
    end
  end

  def handle_recaptcha_failure
    render json: {error: "There was an temporary error preventing your payment. Please try again. If it persists, please contact support@commitchange.com with error code: 5X4J "}, status: :unprocessable_entity
  end
end
