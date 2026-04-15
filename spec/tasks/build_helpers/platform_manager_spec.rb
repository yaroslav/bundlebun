# frozen_string_literal: true

require_relative '../../../tasks/build_helpers'

RSpec.describe BuildHelpers::PlatformManager do
  describe '.bun_platform_for' do
    context 'with linux platforms' do
      it 'maps bare x86_64-linux to glibc Bun' do
        expect(described_class.bun_platform_for('x86_64-linux')).to eq('linux-x64')
      end

      it 'maps x86_64-linux-gnu to glibc Bun' do
        expect(described_class.bun_platform_for('x86_64-linux-gnu')).to eq('linux-x64')
      end

      it 'maps x86_64-linux-musl to musl Bun' do
        expect(described_class.bun_platform_for('x86_64-linux-musl')).to eq('linux-x64-musl')
      end

      it 'maps bare aarch64-linux to glibc Bun' do
        expect(described_class.bun_platform_for('aarch64-linux')).to eq('linux-aarch64')
      end

      it 'maps aarch64-linux-gnu to glibc Bun' do
        expect(described_class.bun_platform_for('aarch64-linux-gnu')).to eq('linux-aarch64')
      end

      it 'maps aarch64-linux-musl to musl Bun' do
        expect(described_class.bun_platform_for('aarch64-linux-musl')).to eq('linux-aarch64-musl')
      end
    end

    context 'with darwin platforms' do
      it 'maps bare arm64-darwin to aarch64 Bun' do
        expect(described_class.bun_platform_for('arm64-darwin')).to eq('darwin-aarch64')
      end

      it 'maps versioned arm64-darwin22 to aarch64 Bun' do
        expect(described_class.bun_platform_for('arm64-darwin22')).to eq('darwin-aarch64')
      end

      it 'maps x86_64-darwin to x64 Bun' do
        expect(described_class.bun_platform_for('x86_64-darwin')).to eq('darwin-x64')
      end

      it 'maps versioned x86_64-darwin23 to x64 Bun' do
        expect(described_class.bun_platform_for('x86_64-darwin23')).to eq('darwin-x64')
      end
    end

    context 'with windows platforms' do
      it 'maps x64-mingw-ucrt to windows-x64 Bun' do
        expect(described_class.bun_platform_for('x64-mingw-ucrt')).to eq('windows-x64')
      end
    end

    context 'with unknown platforms' do
      it 'returns nil for an unrecognized tuple' do
        expect(described_class.bun_platform_for('unknown-platform')).to be_nil
      end

      it 'returns nil for a recognized OS on an unsupported CPU' do
        expect(described_class.bun_platform_for('powerpc64-linux')).to be_nil
      end
    end
  end

  describe '.binary_name_for' do
    it 'returns bun.exe for windows mingw' do
      expect(described_class.binary_name_for('x64-mingw-ucrt')).to eq('bun.exe')
    end

    it 'returns bun for linux glibc' do
      expect(described_class.binary_name_for('x86_64-linux')).to eq('bun')
    end

    it 'returns bun for linux musl' do
      expect(described_class.binary_name_for('x86_64-linux-musl')).to eq('bun')
    end

    it 'returns bun for darwin' do
      expect(described_class.binary_name_for('arm64-darwin')).to eq('bun')
    end
  end
end
