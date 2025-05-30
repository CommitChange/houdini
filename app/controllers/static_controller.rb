# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
class StaticController < ApplicationController
  layout "layouts/static"

  def terms_and_privacy
    @theme = "minimal"
  end

  def ccs
    if Settings.ccs&.ccs_method.presence == "github"
      redirect_to "https://github.com/#{Settings.ccs.options.account}/#{Settings.ccs.options.repo}/tree/#{git_hash}",
        allow_other_host: true
    elsif create_archive
      send_file(temp_file, type: "application/gzip")
    else
      head 500
    end
  end

  private

  def git_hash
    @git_hash ||= File.read(Rails.root.join("CCS_HASH").to_s)
  end

  def temp_file
    @temp_file ||= Rails.root.join("tmp/#{Time.current.to_i}.tar.gz").to_s
  end

  def create_archive
    Kernel.system("git archive --format=tar.gz -o #{temp_file} HEAD")
  end
end
