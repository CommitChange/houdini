# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
Rails.application.config.after_initialize do
  # this is hacky way to autoload app/legacy_lib/to_deprecated_h.rb on startup
  ToDeprecatedH
end
