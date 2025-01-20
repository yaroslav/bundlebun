# frozen_string_literal: true

# Remind that we need to install an executable first
# when running integration tests
RSpec.configure do |config|
  config.before(:each, type: :integration) do
    unless Bundlebun::Runner.binary_path_exist?
      skip('Bun binary is not downloaded, download it using `rake bundlebun:download` first')
    end
  end
end

def capture(cmd)
  env = {
    'BUNDLE_GEMFILE' => File.join(tmp_dir, 'Gemfile'),
    'BUNDLE_PATH' => File.join(tmp_dir, 'vendor/bundle'),
    'BUNDLE_APP_CONFIG' => File.join(tmp_dir, '.bundle'),
    'BUNDLE_DISABLE_SHARED_GEMS' => 'true'
  }

  path_separator = /mswin|mingw|cygwin/.match?(RbConfig::CONFIG['host_os']) ? ';' : ':'
  env['PATH'] = [File.join(tmp_dir, "bin"), ENV["PATH"]].join(path_separator)

  Open3.capture2e(env, cmd)
end
