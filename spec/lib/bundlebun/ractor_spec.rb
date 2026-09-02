# frozen_string_literal: true

require 'open3'

# Ractor readiness.
#
# Non-main Ractors can neither write class-level instance variables nor read
# unshareable (unfrozen) values from them. So every class-level memo in
# bundlebun has to be warmed on the main Ractor before any other Ractor is
# spawned, and it has to hold a frozen value.
RSpec.describe 'Ractor readiness', if: defined?(Ractor) do
  # Ruby 3.x: Ractor#take. Ruby 4.0: Ractor#value.
  def ractor_value(ractor)
    ractor.respond_to?(:value) ? ractor.value : ractor.take
  end

  around do |example|
    previous = Warning[:experimental]
    Warning[:experimental] = false
    example.run
  ensure
    Warning[:experimental] = previous
  end

  describe 'memoized paths' do
    # Simulates the boot: memos get computed on the main Ractor first.
    before do
      Bundlebun::Runner.make_shareable
      Bundlebun::EnvPath.separator
    end

    it 'exposes Runner.binary_path to a non-main Ractor' do
      expect(ractor_value(Ractor.new { Bundlebun::Runner.binary_path })).to eq(Bundlebun::Runner.binary_path)
    end

    it 'exposes Runner.full_directory to a non-main Ractor' do
      expect(ractor_value(Ractor.new { Bundlebun::Runner.full_directory })).to eq(Bundlebun::Runner.full_directory)
    end

    it 'exposes Runner.binstub_path to a non-main Ractor' do
      expect(ractor_value(Ractor.new { Bundlebun::Runner.binstub_path })).to eq(Bundlebun::Runner.binstub_path)
    end

    it 'exposes Runner.full_binstub_path to a non-main Ractor' do
      expect(ractor_value(Ractor.new { Bundlebun::Runner.full_binstub_path })).to eq(Bundlebun::Runner.full_binstub_path)
    end

    it 'exposes Runner.binstub_or_binary_path to a non-main Ractor' do
      expect(ractor_value(Ractor.new { Bundlebun::Runner.binstub_or_binary_path })).to eq(Bundlebun::Runner.binstub_or_binary_path)
    end

    it 'exposes Platform.windows? to a non-main Ractor' do
      expect(ractor_value(Ractor.new { Bundlebun::Platform.windows? })).to eq(Bundlebun::Platform.windows?)
    end

    it 'exposes EnvPath.separator to a non-main Ractor' do
      expect(ractor_value(Ractor.new { Bundlebun::EnvPath.separator })).to eq(Bundlebun::EnvPath.separator)
    end
  end

  describe 'integration patches' do
    before { Bundlebun::Runner.make_shareable }

    it 'builds cssbundling commands from a non-main Ractor' do
      command = ractor_value(Ractor.new { Bundlebun::Integrations::Cssbundling::Tasks.build_command })
      expect(command).to eq(Bundlebun::Integrations::Cssbundling::Tasks.build_command)
    end

    it 'builds jsbundling commands from a non-main Ractor' do
      command = ractor_value(Ractor.new { Bundlebun::Integrations::Jsbundling::Tasks.install_command })
      expect(command).to eq(Bundlebun::Integrations::Jsbundling::Tasks.install_command)
    end

    it 'resolves the vite-ruby binstub from a non-main Ractor' do
      path = ractor_value(Ractor.new do
        Object.new.extend(Bundlebun::Integrations::ViteRuby::RunnerExtensions).bun_binstub_path
      end)
      expect(path).to eq(Bundlebun::Runner.binstub_or_binary_path)
    end
  end

  describe 'boot' do
    it 'warms and freezes every memoized path when the gem is required' do
      script = <<~RUBY
        require 'bundlebun'
        ivars = %i[@binary_path @binstub_path @full_binstub_path @full_directory]
        print ivars.all? { |ivar|
          Bundlebun::Runner.instance_variable_defined?(ivar) && Bundlebun::Runner.instance_variable_get(ivar).frozen?
        }
      RUBY
      lib = File.expand_path('../../../lib', __dir__)

      output, status = Open3.capture2(RbConfig.ruby, '-I', lib, '-e', script)

      expect(status).to be_success
      expect(output).to eq('true')
    end
  end
end
