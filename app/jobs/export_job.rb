# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
class ExportJob < ApplicationJob
  queue_as :default

  def perform(nonprofit, user, export)
  end

  before_enqueue do |job|
    job.arguments.push(Export.create(nonprofit: job.nonprofit, user: job.user, status: :queued))
  end

  before_perform do |job|
    job.arguments.push(Export.create(nonprofit: job.nonprofit, user: job.user, status: :queued)) unless export
    job.export.update(status: :started)
  end

  after_perform do |job|
    job.export.update(status: :completed, ended:Time.current)
  end

  rescue_from 'Exception' do |exception|
    self.export.update(status: :failed, ended:Time.current, exception: exception.to_s)
    raise exception
  end

  protected
  
  # we use these where to get the args in various callbacks
  def nonprofit
    arguments[0]
  end

  def user
    arguments[1]
  end
  
  def export
    arguments[2]
  end


end
