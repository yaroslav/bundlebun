# frozen_string_literal: true

RSpec.describe Bundlebun do
  it 'has a base version number' do
    expect(Bundlebun::VERSION).not_to be nil
  end

  describe '.call' do
    before do
      allow(Bundlebun::Runner).to receive(:call)
    end

    it 'delegates to Runner.call' do
      arguments = 'install package_name'
      expect(Bundlebun::Runner).to receive(:call).with(arguments)

      Bundlebun.call(arguments)
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
