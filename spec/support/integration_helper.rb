# frozen_string_literal: true

# Remind that we need to install an executable first
# when running integration tests
RSpec.configure do |config|
  config.before(:each, type: :integration) do
    unless Bundlebun::Runner.binary_path_exist?
      skip('Bun binary is not downloaded, download with `rake bundlebun:download` first')
    end
  end
end
