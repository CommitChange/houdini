Recaptcha.configure do |config|
  config.api_server_url = 'https://www.google.com/recaptcha/api.js',
  config.verify_url =   'https://recaptchaenterprise.googleapis.com/v1beta1/projects/307417/assessments'
end