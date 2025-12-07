# frozen_string_literal: true

require 'bundler'
require 'open3'

RSpec.describe 'ExecJS integration', type: :integration do
  let(:tmp_dir) { Dir.mktmpdir('execjs_test') }
  let(:gem_root) { File.expand_path('../../../../', __dir__) }

  before(:each) do
    Dir.chdir(tmp_dir) do
      Bundler.with_unbundled_env do
        # Create initial Gemfile with Rails
        File.write('Gemfile', <<~RUBY)
          source 'https://rubygems.org'
          gem 'rails'
        RUBY
        _output, status = capture("bundle install && bundle binstubs rails && bundle exec rails new . --skip-git --skip-test --skip-system-test --skip-bootsnap --skip-bundle --force")
        expect(status).to be_success

        File.write('Gemfile', <<~RUBY, mode: 'a+')
          gem 'execjs'
          gem 'bundlebun', path: '#{gem_root}'
        RUBY
        _output, status = capture("bundle install")
        expect(status).to be_success

        # Install bundlebun
        _output, status = capture("bundle binstubs rake && bundle exec rake bun:install")
        expect(status).to be_success
      end
    end
  end

  after(:each) do
    FileUtils.rm_rf(tmp_dir)
  end

  it 'successfully uses the Bun runtime' do
    Dir.chdir(tmp_dir) do
      Bundler.with_unbundled_env do
        output, status = capture("bundle exec rails runner \"puts ExecJS.eval('Bun.version')\"")
        expect(status).to be_success
        expect(output).to match(/\d+\.\d+\.\d+/)
      end
    end
  end
end
