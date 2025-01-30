# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bundlebun::EnvPath do
  let(:sample_path) { '/usr/local/bin:/usr/bin:/bin' }

  before do
    # Store original PATH
    @original_env_path = ENV['PATH']
    ENV['PATH'] = sample_path
  end

  after do
    # Restore original PATH
    ENV['PATH'] = @original_env_path
  end

  describe 'accessing the PATH' do
    it 'returns the current PATH environment variable' do
      expect(described_class.path).to eq(sample_path)
    end

    it 'sets a new PATH value' do
      new_path = '/custom/path'
      described_class.path = new_path
      expect(ENV['PATH']).to eq(new_path)
    end
  end

  describe 'prepending a path' do
    it 'prepends a new path to PATH' do
      new_path = '/opt/bun/bin'
      described_class.prepend(new_path)

      expected = Bundlebun::Platform.windows? ?
        "#{new_path};#{sample_path}" :
        "#{new_path}:#{sample_path}"

      expect(ENV['PATH']).to eq(expected)
    end

    it 'does nothing if path is already at the start' do
      new_path = '/opt/bun/bin'
      ENV['PATH'] = "#{new_path}#{described_class.separator}#{sample_path}"

      described_class.prepend(new_path)
      expect(ENV['PATH']).to eq("#{new_path}#{described_class.separator}#{sample_path}")
    end

    it 'is case-insensitive on Windows' do
      allow(Bundlebun::Platform).to receive(:windows?).and_return(true)

      new_path = '/Opt/Bun/Bin'
      ENV['PATH'] = "/opt/bun/bin;#{sample_path}"

      described_class.prepend(new_path)
      expect(ENV['PATH']).to eq("/opt/bun/bin;#{sample_path}")
    end
  end

  describe 'detecting the separator' do
    it 'returns the correct separator for the platform' do
      expected_separator = Bundlebun::Platform.windows? ? ';' : ':'
      expect(described_class.separator).to eq(expected_separator)
    end
  end
end
