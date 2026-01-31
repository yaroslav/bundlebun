# frozen_string_literal: true

RSpec.describe Bundlebun::Runner do
  let(:runner) { described_class.new }
  let(:binary_path) { described_class.binary_path }

  # Prevent any bun execution from leaking through in tests
  before do
    allow(Kernel).to receive(:system).and_return(true)
    allow(Kernel).to receive(:exec)
  end

  describe 'with vendor directory' do
    describe 'relative' do
      it 'returns the vendor/bun path' do
        expect(described_class.relative_directory).to eq('lib/bundlebun/vendor/bun')
      end
    end

    describe 'with full directory path' do
      let(:expected_path) { File.expand_path('../../../lib/bundlebun/vendor/bun', __dir__) }

      it 'returns absolute path to vendor/bun directory' do
        expect(described_class.full_directory).to eq(expected_path)
      end
    end
  end

  describe 'returning path to the binary' do
    context 'on Unix-like systems' do
      before do
        allow(described_class).to receive(:binary_path).and_call_original

        stub_const('RbConfig', Module.new)
        stub_const('RbConfig::CONFIG', {
          'host_os' => 'darwin19.0.0'
        })
        Bundlebun::Platform.remove_instance_variable(:@windows) if Bundlebun::Platform.instance_variable_defined?(:@windows)
        described_class.remove_instance_variable(:@binary_path) if described_class.instance_variable_defined?(:@binary_path)
      end

      after do
        Bundlebun::Platform.remove_instance_variable(:@windows) if Bundlebun::Platform.instance_variable_defined?(:@windows)
        described_class.remove_instance_variable(:@binary_path) if described_class.instance_variable_defined?(:@binary_path)
      end

      it 'returns path with bun binary' do
        expect(File.basename(described_class.binary_path)).to eq('bun')
      end
    end

    context 'on Windows' do
      before do
        allow(described_class).to receive(:binary_path).and_call_original

        stub_const('RbConfig', Module.new)
        stub_const('RbConfig::CONFIG', {
          'host_os' => 'mingw32'
        })
        Bundlebun::Platform.remove_instance_variable(:@windows) if Bundlebun::Platform.instance_variable_defined?(:@windows)
        described_class.remove_instance_variable(:@binary_path) if described_class.instance_variable_defined?(:@binary_path)
      end

      after do
        Bundlebun::Platform.remove_instance_variable(:@windows) if Bundlebun::Platform.instance_variable_defined?(:@windows)
        described_class.remove_instance_variable(:@binary_path) if described_class.instance_variable_defined?(:@binary_path)
      end

      it 'returns path with bun.exe binary' do
        expect(File.basename(described_class.binary_path)).to eq('bun.exe')
      end
    end
  end

  describe 'when checking binary existence' do
    it 'returns true when binary exists' do
      allow(File).to receive(:exist?).with(described_class.binary_path).and_return(true)
      expect(described_class.binary_path_exist?).to be true
    end

    it 'returns false when binary does not exist' do
      allow(File).to receive(:exist?).with(described_class.binary_path).and_return(false)
      expect(described_class.binary_path_exist?).to be false
    end
  end

  describe 'binstub handling' do
    context 'with binstub path' do
      context 'on Windows' do
        before do
          stub_const('RbConfig', Module.new)
          stub_const('RbConfig::CONFIG', {
            'host_os' => 'mingw32'
          })
          Bundlebun::Platform.remove_instance_variable(:@windows) if Bundlebun::Platform.instance_variable_defined?(:@windows)
          described_class.remove_instance_variable(:@binary_path) if described_class.instance_variable_defined?(:@binary_path)
        end

        after do
          Bundlebun::Platform.remove_instance_variable(:@windows) if Bundlebun::Platform.instance_variable_defined?(:@windows)
          described_class.remove_instance_variable(:@binary_path) if described_class.instance_variable_defined?(:@binary_path)
        end

        it 'returns the binstub path as-is on Windows' do
          expect(described_class.binstub_path).to eq('bin/bun.cmd')
        end
      end

      context 'on Unix-like systems' do
        before do
          stub_const('RbConfig', Module.new)
          stub_const('RbConfig::CONFIG', {
            'host_os' => 'darwin19.0.0'
          })
          Bundlebun::Platform.remove_instance_variable(:@windows) if Bundlebun::Platform.instance_variable_defined?(:@windows)
          described_class.remove_instance_variable(:@binary_path) if described_class.instance_variable_defined?(:@binary_path)
        end

        after do
          Bundlebun::Platform.remove_instance_variable(:@windows) if Bundlebun::Platform.instance_variable_defined?(:@windows)
          described_class.remove_instance_variable(:@binary_path) if described_class.instance_variable_defined?(:@binary_path)
        end

        it 'returns the binstub path as-is on Unix-like systems' do
          expect(described_class.binstub_path).to eq('bin/bun')
        end
      end
    end

    context 'when binstub exists' do
      before do
        allow(File).to receive(:exist?).and_return(true)
      end

      it 'returns true' do
        expect(described_class.binstub_exist?).to be true
      end
    end

    context 'when binstub does not exist' do
      before do
        allow(File).to receive(:exist?).and_return(false)
      end

      it 'returns false' do
        expect(described_class.binstub_exist?).to be false
      end
    end

    describe 'with full binstub path' do
      before do
        allow(File).to receive(:expand_path).and_call_original
      end

      it 'returns absolute path for binstub' do
        expect(described_class.full_binstub_path).to eq(File.expand_path(described_class.binstub_path))
      end
    end

    describe 'returning binstub or true binary path' do
      let(:binary_path) { described_class.binary_path }
      let(:full_binstub_path) { described_class.full_binstub_path }

      context 'when binstub exists' do
        before do
          allow(File).to receive(:exist?).and_return(true)
        end

        it 'returns full binstub path' do
          expect(described_class.binstub_or_binary_path).to eq(full_binstub_path)
        end
      end

      context 'when binstub does not exist' do
        before do
          allow(File).to receive(:exist?).and_return(false)
        end

        it 'returns binary path' do
          expect(described_class.binstub_or_binary_path).to eq(binary_path)
        end
      end
    end
  end

  describe '#exec' do
    before do
      allow(File).to receive(:exist?).with(binary_path).and_return(true)
    end

    it 'replaces process with bun using string arguments' do
      runner = described_class.new('install --no-save')
      expect(Kernel).to receive(:exec).with("#{binary_path} install --no-save")
      runner.exec
    end

    it 'replaces process with bun using array arguments' do
      runner = described_class.new(['install', '--no-save'])
      expect(Kernel).to receive(:exec).with("#{binary_path} install --no-save")
      runner.exec
    end

    it 'replaces process with bun without arguments' do
      runner = described_class.new
      expect(Kernel).to receive(:exec).with(binary_path)
      runner.exec
    end

    it 'exits with code 127 if bun executable does not exist' do
      allow(File).to receive(:exist?).with(binary_path).and_return(false)
      runner = described_class.new('test')

      expect(Kernel).to receive(:warn).with(/Unable to run Bun/)
      expect(Kernel).to receive(:exit).with(127)

      runner.exec
    end
  end

  describe '#call' do
    before do
      allow(File).to receive(:exist?).with(binary_path).and_return(true)
    end

    it 'is an alias for #exec' do
      runner = described_class.new('--version')
      expect(Kernel).to receive(:exec).with("#{binary_path} --version")
      runner.call
    end
  end

  describe '#system' do
    before do
      allow(File).to receive(:exist?).with(binary_path).and_return(true)
    end

    it 'runs bun as a subprocess with string arguments' do
      runner = described_class.new('install --no-save')
      expect(Kernel).to receive(:system).with("#{binary_path} install --no-save").and_return(true)
      expect(runner.system).to be true
    end

    it 'runs bun as a subprocess with array arguments' do
      runner = described_class.new(['install', '--no-save'])
      expect(Kernel).to receive(:system).with("#{binary_path} install --no-save").and_return(true)
      expect(runner.system).to be true
    end

    it 'runs bun without arguments' do
      runner = described_class.new
      expect(Kernel).to receive(:system).with(binary_path).and_return(true)
      expect(runner.system).to be true
    end

    it 'returns false when bun exits with error' do
      runner = described_class.new('invalid-command')
      expect(Kernel).to receive(:system).and_return(false)
      expect(runner.system).to be false
    end

    it 'returns nil when execution fails' do
      runner = described_class.new('test')
      expect(Kernel).to receive(:system).and_return(nil)
      expect(runner.system).to be_nil
    end

    it 'exits with code 127 if bun executable does not exist' do
      allow(File).to receive(:exist?).with(binary_path).and_return(false)
      runner = described_class.new('test')

      expect(Kernel).to receive(:warn).with(/Unable to run Bun/)
      expect(Kernel).to receive(:exit).with(127)

      runner.system
    end
  end

  describe '.exec' do
    before do
      allow(File).to receive(:exist?).with(binary_path).and_return(true)
    end

    it 'creates a runner and calls exec' do
      expect(Kernel).to receive(:exec).with("#{binary_path} --version")
      described_class.exec('--version')
    end
  end

  describe '.call' do
    before do
      allow(File).to receive(:exist?).with(binary_path).and_return(true)
    end

    it 'is an alias for .exec' do
      expect(Kernel).to receive(:exec).with("#{binary_path} --version")
      described_class.call('--version')
    end
  end

  describe '.system' do
    before do
      allow(File).to receive(:exist?).with(binary_path).and_return(true)
    end

    it 'creates a runner and calls system' do
      expect(Kernel).to receive(:system).with("#{binary_path} --version").and_return(true)
      expect(described_class.system('--version')).to be true
    end
  end
end
