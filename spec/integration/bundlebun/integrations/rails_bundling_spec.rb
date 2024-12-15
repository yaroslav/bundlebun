# frozen_string_literal: true

require 'bundler'
require 'open3'

RSpec.describe 'Rails bundling integrations', type: :integration do
  let(:tmp_dir) { Dir.mktmpdir('rails_bundling_test') }
  let(:gem_root) { File.expand_path('../../../../', __dir__) }

  # So, this is a spec that actually checks that something *FAILS*.
  #
  # We are creating a proper Rails application in a temp directory,
  # using `rails new`, then we add `cssbundling-rails`,
  # `jsbundling-rails` and `bundlebun`. After that, we do the
  # recommended install tasks for those packing libraries, and
  # properly install bundlebun.
  # At this point, we need to check that both CSS and JS builds
  # succeed and we need to make sure they are run using Bun.
  #
  # Something like:
  #
  #   File.write('bun-check-plugin.js', <<~JS)
  #     import process from "node:process";
  #
  #     module.exports = () => ({
  #       postcssPlugin: 'bun-check',
  #       Once(root) {
  #         root.append({ text: `/* Built with Bun ${Bun.version} */` })
  #       }
  #     })
  #     module.exports.postcss = true
  #   JS
  #   File.write('postcss.config.js', <<~JS)
  #     module.exports = {
  #       plugins: [
  #         require('./bun-check-plugin.js')()
  #       ]
  #     }
  #   JS
  #
  #   ...
  #
  #   output, status = Open3.capture2e("bundle exec rake css:build")
  #   expect(status).to be_success
  #   expect(File).to exist('app/assets/builds/application.css')
  #   css_output = File.read('app/assets/builds/application.css')
  #   expect(css_output).to match(/Built with Bun \d+\.\d+\.\d+/)
  #
  # However, Bun acts weird. Long story short, it.. runs Node. Check:
  #
  #   https://bun.sh/docs/cli/bunx#shebangs
  #
  # There is a way to fight this behaviour, but it seems to be bugged now:
  #
  #   https://github.com/oven-sh/bun/issues/11869
  #
  # And so, the integration test fails.
  #
  # Instead, we fail it purposefully and see that the mentioned gems
  # contain an error message that directly mentiones our binstub or
  # the path to bundlebun included Bun binary. This way, we would know
  # that the build script at least tried to run Bun.
  # Fun times.

  before(:each) do
    Dir.chdir(tmp_dir) do
      Bundler.with_unbundled_env do
        # Create initial Gemfile with Rails
        File.write('Gemfile', <<~RUBY)
          source 'https://rubygems.org'
          gem 'rails'
        RUBY
        _output, status = capture("bundle install && bundle exec rails new . --skip-git --skip-test --skip-system-test --skip-bootsnap --skip-bundle --force")
        expect(status).to be_success

        # Update Gemfile with our gems
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

        # install bundlebun
        _output, status = capture("bundle exec rake bun:install")
        expect(status).to be_success
        expect(File).to exist('lib/tasks/bundlebun.rake')

        # Remove the build scripts to force failure
        json = JSON.parse(File.read('package.json'))
        json['scripts'] = {}
        File.write('package.json', JSON.pretty_generate(json))
      end
    end
  end

  after(:each) do
    FileUtils.rm_rf(tmp_dir)
  end

  describe Bundlebun::Integrations::Cssbundling do
    it 'shows bundlebun binstub in error message when failing' do
      Dir.chdir(tmp_dir) do
        Bundler.with_unbundled_env do
          output, _status = capture("bundle exec rake css:build")

          expect(output).to match(/cssbundling-rails: Command build failed, ensure `(bin\/bun|bundlebun)/)
        end
      end
    end
  end

  describe Bundlebun::Integrations::Cssbundling do
    it 'shows bundlebun binstub in error message when failing' do
      Dir.chdir(tmp_dir) do
        Bundler.with_unbundled_env do
          output, _status = capture("bundle exec rake javascript:build")

          expect(output).to match(/jsbundling-rails.+ensure.+(bin\/bun|bundlebun)/i)
        end
      end
    end
  end

  def capture(cmd)
    env = {
      'BUNDLE_GEMFILE' => File.join(tmp_dir, 'Gemfile'),
      'BUNDLE_PATH' => File.join(tmp_dir, 'vendor/bundle'),
      'BUNDLE_APP_CONFIG' => File.join(tmp_dir, '.bundle'),
      'BUNDLE_DISABLE_SHARED_GEMS' => 'true',
      'PATH' => "#{File.join(tmp_dir, "bin")}:#{File.join(tmp_dir, "vendor/bundle/bin")}:#{ENV["PATH"]}"
    }
    Open3.capture2e(env, cmd)
  end
end
