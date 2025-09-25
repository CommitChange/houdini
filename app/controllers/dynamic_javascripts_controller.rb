class DynamicJavascriptsController < ApplicationController
  protect_from_forgery except: :show
  layout false

  def show
    template_name = params[:name].presence

    # Only allow known names (to avoid directory traversal)
    view_templates = Dir.entries(Rails.root.join('app/views/dynamic_javascripts'))
    view_templates.shift(2) # toss out . and .. directories

    head :not_found and return unless view_templates.include?(template_name)
    render Rails.root.join("app/dynamic_javascripts/#{template_name}")
  end
end
