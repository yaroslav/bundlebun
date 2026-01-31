# frozen_string_literal: true

RSpec.describe Bundlebun do
  let(:binary_path) { Bundlebun::Runner.binary_path }

  it 'has a base version number' do
    expect(Bundlebun::VERSION).not_to be nil
  end

  describe '.call' do
    before do
      allow(File).to receive(:exist?).with(binary_path).and_return(true)
    end

    it 'replaces the process with bun' do
      arguments = 'install package_name'
      expect(Kernel).to receive(:exec).with("#{binary_path} #{arguments}")

      Bundlebun.call(arguments)
    end

    it 'works with the .() shorthand syntax' do
      expect(Kernel).to receive(:exec).with("#{binary_path} --version")
      Bundlebun.('--version') # rubocop:disable Style/LambdaCall
    end

    it 'works with array arguments' do
      expect(Kernel).to receive(:exec).with("#{binary_path} add postcss")
      Bundlebun.call(['add', 'postcss'])
    end
  end

  describe '.exec' do
    before do
      allow(File).to receive(:exist?).with(binary_path).and_return(true)
    end

    it 'replaces the process with bun' do
      arguments = 'run dev'
      expect(Kernel).to receive(:exec).with("#{binary_path} #{arguments}")

      Bundlebun.exec(arguments)
    end

    it 'works with array arguments' do
      expect(Kernel).to receive(:exec).with("#{binary_path} x --bun vite")

      Bundlebun.exec(['x', '--bun', 'vite'])
    end
  end

  describe '.system' do
    before do
      allow(File).to receive(:exist?).with(binary_path).and_return(true)
    end

    it 'runs bun as subprocess and returns result' do
      arguments = 'install package_name'
      expect(Kernel).to receive(:system).with("#{binary_path} #{arguments}").and_return(true)

      expect(Bundlebun.system(arguments)).to be true
    end

    it 'returns false when bun exits with error' do
      expect(Kernel).to receive(:system).and_return(false)
      expect(Bundlebun.system('invalid')).to be false
    end

    it 'returns nil when execution fails' do
      expect(Kernel).to receive(:system).and_return(nil)
      expect(Bundlebun.system('test')).to be_nil
    end
  end

  it 'prepends bun directory to PATH' do
    expect(Bundlebun::EnvPath).to receive(:prepend).with(Bundlebun::Runner.full_directory)
    Bundlebun.prepend_to_path
  end

  it 'loads integrations' do
    expect(Bundlebun::Integrations).to receive(:bun!)
    Bundlebun.load_integrations
  end

  it 'attempts to load the rake task' do
    expect(described_class).to respond_to(:load_tasks)
    expect { described_class.load_tasks }.not_to raise_error
  end

  it 'has a binstub file in `exe/`' do
    expect(File.exist?(File.expand_path('../../exe/bundlebun', __dir__))).to be true
  end

  %w[bun bun? bun!].each do |m|
    it m do
      expect(Bundlebun.send(m)).to eq('Bun')
    end
  end
end
