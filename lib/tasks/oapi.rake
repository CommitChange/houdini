


namespace :oapi do
  task gen: [:environment] do
    ENV['store'] = 'tmp/openapi.json'
    require 'grape-swagger/rake/oapi_tasks'
    GrapeSwagger::Rake::OapiTasks.new(::Houdini::API)
    ::Rake::Task['oapi:fetch']
  end
end