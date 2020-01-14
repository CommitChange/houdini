module Nonprofits
    class StripeAccountsController < ApplicationController
        include Controllers::NonprofitHelper
        before_filter :authenticate_nonprofit_admin!

        layout 'layouts/apified'
        @theme = 'minimal'

        def index
            render_json { (current_nonprofit.stripe_account || {}).to_json( except: [:object, :id, :created_at, :updated_at])}
        end

        def verification
            @current_nonprofit = current_nonprofit
        end

        def checking

        end

        def retry

        end

        def account_link
            if (current_nonprofit.stripe_account_id)
                render json: Stripe::AccountLink.create({
                    account:current_nonprofit.stripe_account_id,
                    failure_url: nonprofits_stripe_account_url(current_nonprofit.id),
                    success_url: confirm_nonprofits_stripe_account_url(current_nonprofit.id),
                    type: 'custom_account_verification',
                    collect: 'eventually_due'
                }).to_json, status: 200
            else
                render json:{error: "No Stripe account for Nonprofit."}, status: 400
            end
        end
    end
end
