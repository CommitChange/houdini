RSpec.configure do |config|
  config.before(:suite) do

    $stdout.puts "\n🐢  Precompiling assets.\n"

    # The code to run build task

    `npm run build`
  end
end