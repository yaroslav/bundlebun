# frozen_string_literal: true

require_relative '../../../tasks/build_helpers'

RSpec.describe BuildHelpers::GemBuilder do
  let(:gemspec) do
    instance_double(Gem::Specification,
      version: '0.1.0.1.0.0',
      platform: 'ruby',
      files: ['existing/files'])
  end
  let(:platform_gemspec) { instance_double(Gem::Specification) }
  let(:downloader) { instance_double(BuildHelpers::BunDownloader) }
  let(:builder) { described_class.new(gemspec) }
  let(:test_binary_path) { 'tmp/test_vendor/bun/bun' }

  before do
    # Quiet the output
    allow(builder).to receive(:puts)
    allow(builder).to receive(:warn)

    # Stub basic operations
    stub_basic_operations
    stub_gemspec_behavior
    stub_downloader
  end

  describe 'building for all platforms' do
    it 'builds a gem for each supported platform' do
      BuildHelpers::PlatformManager::PLATFORM_MAPPING.each_key do |platform|
        expect(downloader).to receive(:download_for)
          .with(platform)
          .and_return(test_binary_path)
      end

      built_gems = builder.build_for_all_platforms
      expect(built_gems).to all(eq('fake.gem'))
      expect(built_gems.length).to eq(BuildHelpers::PlatformManager::PLATFORM_MAPPING.length)
    end

    it 'cleans up after itself' do
      BuildHelpers::PlatformManager::PLATFORM_MAPPING.each_key do |platform|
        allow(downloader).to receive(:download_for)
          .with(platform)
          .and_return(test_binary_path)
      end

      builder.build_for_all_platforms
      BuildHelpers::PlatformManager::PLATFORM_MAPPING.each_key do |platform|
        expect(FileUtils).to have_received(:rm_rf).with("tmp/build_#{platform}")
      end
    end
  end

  describe 'error handling' do
    context 'when download fails' do
      before do
        BuildHelpers::PlatformManager::PLATFORM_MAPPING.each_key do |platform|
          allow(downloader).to receive(:download_for)
            .with(platform)
            .and_return(nil)
        end
        allow(downloader).to receive(:download_for)
          .with('x86_64-linux')
          .and_raise(Down::NotFound.new('Not found'))
      end

      it 'includes failed platform in error message' do
        expect { builder.build_for_all_platforms }
          .to raise_error(BuildHelpers::GemBuilder::BuildError, /x86_64-linux/)
      end
    end

    context 'with multiple platform failures' do
      before do
        allow(downloader).to receive(:download_for)
          .with(any_args)
          .and_raise(Down::NotFound.new('Not found'))
      end

      it 'includes all failed platforms in error message' do
        expect { builder.build_for_all_platforms }
          .to raise_error(BuildHelpers::GemBuilder::BuildError,
            /#{BuildHelpers::PlatformManager::PLATFORM_MAPPING.keys.join(".*")}/)
      end
    end
  end

  private

  def stub_basic_operations
    # File operations
    allow(FileUtils).to receive(:mkdir_p)
    allow(FileUtils).to receive(:rm_rf)
    allow(FileUtils).to receive(:rm_f)
    allow(FileUtils).to receive(:cp)

    # Ensure file operations are safe
    allow(File).to receive(:join) do |*paths|
      paths.join('/').sub(%r{^vendor/bun}, 'tmp/test_vendor/bun')
    end

    allow(File).to receive(:exist?).and_return(true)
    allow(File).to receive(:basename).and_return('bun')
  end

  def stub_gemspec_behavior
    allow(gemspec).to receive(:dup).and_return(platform_gemspec)
    allow(platform_gemspec).to receive(:platform=)
    allow(platform_gemspec).to receive(:files=)
    allow(Gem::Package).to receive(:build).and_return('fake.gem')
  end

  def stub_downloader
    allow(BuildHelpers::BunDownloader).to receive(:new)
      .with('1.0.0')
      .and_return(downloader)
  end
end
