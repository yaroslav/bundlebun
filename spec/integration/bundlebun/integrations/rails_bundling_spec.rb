# frozen_string_literal: true

require 'bundler'
require 'open3'

RSpec.describe 'Rails bundling integrations', type: :integration do
  let(:tmp_dir) { Dir.mktmpdir('rails_bundling_test') }
  let(:gem_root) { File.expand_path('../../../../', __dir__) }

  before(:each) do
    Dir.chdir(tmp_dir) do
      Bundler.with_unbundled_env do
        File.write('Gemfile', <<~RUBY)
          source 'https://rubygems.org'
          gem 'rails'
        RUBY
        _output, status = capture("bundle install && bundle exec rails new . --skip-git --skip-test --skip-system-test --skip-bootsnap --skip-bundle --force")
        expect(status).to be_success

        File.write('Gemfile', <<~RUBY, mode: 'a+')
          gem 'cssbundling-rails'
          gem 'jsbundling-rails'
          gem 'bundlebun', path: '#{gem_root}'
        RUBY
        _output, status = capture("bundle install")
        expect(status).to be_success

        # Setup directories
        FileUtils.mkdir_p('app/assets/stylesheets')
        FileUtils.mkdir_p('app/assets/builds')
        FileUtils.mkdir_p('app/javascript')

        # Install CSS and JS bundling
        _output, status = capture("bundle exec rails css:install:postcss")
        expect(status).to be_success

        _output, status = capture("bundle exec rails javascript:install:bun")
        expect(status).to be_success

        # Install bundlebun
        _output, status = capture("bundle exec rake bun:install")
        expect(status).to be_success

        # Add Bun version check plugin for CSS
        File.write('bun-check-plugin.js', <<~JS)
          module.exports = () => ({
            postcssPlugin: 'bun-check',
            Once(root) {
              root.append({ text: `/* Built with Bun ${Bun.version} */` })
            }
          })
          module.exports.postcss = true
        JS

        File.write('postcss.config.js', <<~JS)
          module.exports = {
            plugins: [
              require('./bun-check-plugin.js')()
            ]
          }
        JS

        # Add a basic CSS file
        File.write('app/assets/stylesheets/application.postcss.css', <<~CSS)
          body { background: #fff; }
        CSS

        # Add a basic JS file
        File.write('app/javascript/application.js', <<~JS)
          console.log('Runtime check');
        JS

        # Modify bun.config.js to output version
        File.write('bun.config.js', <<~JS)
          console.log('Bun version at config time:', Bun.version);

          const config = {
            sourcemap: "external",
            entrypoints: ["app/javascript/application.js"],
            outdir: "./app/assets/builds",
          };

          await Bun.build(config);
        JS
      end
    end
  end

  after(:each) do
    FileUtils.rm_rf(tmp_dir)
  end

  describe 'CSS building' do
    it 'successfully builds CSS using Bun' do
      Dir.chdir(tmp_dir) do
        Bundler.with_unbundled_env do
          puts "\n=== CSS Building Debug ==="
          puts "Working directory: #{Dir.pwd}"
          puts "Binary path: #{Bundlebun::Runner.binary_path}"
          puts "Binstub path: #{Bundlebun::Runner.binstub_path}"
          puts "Full binstub path: #{File.join(Dir.pwd, Bundlebun::Runner.binstub_path)}"
          puts "PATH: #{ENV["PATH"]}"
          puts "Package.json content:"
          puts File.read('package.json')
          puts "==================\n"

          output, _ = capture("#{Bundlebun::Runner.binstub_or_binary_path} --version")
          puts "Direct bun version: #{output}"

          output, _ = capture("#{Bundlebun::Runner.binstub_or_binary_path} run")
          puts "Available scripts: #{output}"

          output, _ = capture("assoc .cmd")
          puts "CMD association: #{output}"
          output, _ = capture("ftype cmdfile")
          puts "CMD handler: #{output}"

          output, _ = capture("whoami /groups")
          puts "Process permissions: #{output}"

          output, status = capture("bundle exec rake css:build")
          puts output
          expect(status).to be_success

          css_path = 'app/assets/builds/application.css'
          expect(File).to exist(css_path)

          css_content = File.read(css_path)
          expect(css_content).to match(/Built with Bun \d+\.\d+\.\d+/)
        end
      end
    end
  end

  describe 'JavaScript building' do
    it 'successfully builds JavaScript using Bun' do
      Dir.chdir(tmp_dir) do
        Bundler.with_unbundled_env do
          output, status = capture("bundle exec rake javascript:build")
          puts output
          expect(status).to be_success

          # Check that Bun was used by looking for the version output
          expect(output).to match(/Bun version at config time: \d+\.\d+\.\d+/)

          # Check that the file was actually built
          js_path = 'app/assets/builds/application.js'
          expect(File).to exist(js_path)
        end
      end
    end
  end
end
