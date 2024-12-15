# frozen_string_literal: true

require_relative '../../../tasks/build_helpers'

RSpec.describe BuildHelpers::PlatformManager do
  describe 'with platform mapping' do
    it 'maps a full Ruby platform name to Bun platform' do
      expect(described_class.bun_platform_for('arm64-darwin22')).to eq('darwin-aarch64')
    end

    it 'maps generic Ruby platform name to Bun platform' do
      expect(described_class.bun_platform_for('x86_64-linux')).to eq('linux-x64')
      expect(described_class.bun_platform_for('arm64-darwin')).to eq('darwin-aarch64')
    end

    it 'returns nil for unknown platform' do
      expect(described_class.bun_platform_for('unknown-platform')).to be_nil
    end
  end

  describe 'with correct binary names' do
    it 'returns `bun.exe` for Windows platforms' do
      expect(described_class.binary_name_for('x64-mingw-ucrt')).to eq('bun.exe')
    end

    it 'returns `bun` for non-Windows platforms' do
      expect(described_class.binary_name_for('x86_64-linux')).to eq('bun')
    end
  end
end
