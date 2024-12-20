# frozen_string_literal: true

require 'open3'

RSpec.describe Bundlebun::Integrations::ViteRuby, type: :integration do
  let(:tmp_dir) { Dir.mktmpdir('vite_integration_test') }
  let(:gem_root) { File.expand_path('../../../../', __dir__) }

  after(:each) do
    FileUtils.rm_rf(tmp_dir)
  end

  it 'executes vite build through bun' do
    Dir.chdir(tmp_dir) do
      File.write('Gemfile', <<~RUBY)
        source 'https://rubygems.org'
        gem 'rake'
        gem 'vite_ruby'
        gem 'bundlebun', path: '#{gem_root}'
      RUBY

      File.write('Rakefile', <<~RUBY)
        require 'vite_ruby'
        require 'bundlebun'
      RUBY

      _install_output, install_status = Open3.capture2e("cd #{tmp_dir} && bundle install && bundle exec vite install && bundle exec rake bun:install && bundle exec rake bun:install:vite && bundle exec ./bin/bun install")
      expect(install_status).to be_success

      FileUtils.mkdir_p('src')
      File.write('index.html', <<~HTML)
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8">
            <title>Vite Test</title>
          </head>
          <body>
            <script type="module" src="/src/main.js"></script>
          </body>
        </html>
      HTML
      File.write('vite.config.js', <<~JS)
        export default {
          plugins: [{
            name: 'check-bun',
            buildStart() {
              if (typeof Bun === 'undefined') {
                throw new Error('Not running in Bun environment');
              }
              console.log('Bun version:', Bun.version);
            }
          }],
          build: {
            outDir: 'dist'
          }
        }
      JS
      File.write('src/main.js', "console.log('Hi.')")

      output, status = Open3.capture2e("cd #{tmp_dir} && bin/vite build")
      expect(status).to be_success
      expect(output.to_s).to match(/Bun version: \d+\.\d+\.\d+/)
    end
  end
end
