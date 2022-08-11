# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
module React
  class PackrootGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('../templates', __FILE__)
    def copy_file_to_app
      template 'page.tsx.erb', "javascripts/app/#{file_name.underscore}.tsx"
      generate 'react:component', "#{file_name.underscore}/#{file_name.camelize}"
    end
  end
end

