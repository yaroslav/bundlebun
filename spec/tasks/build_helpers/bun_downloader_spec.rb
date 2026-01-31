# frozen_string_literal: true

require_relative '../../../tasks/build_helpers'

require 'octokit'

RSpec.describe BuildHelpers::BunDownloader do
  let(:github_client) { instance_double(Octokit::Client) }
  let(:release) { instance_double('Release', tag_name: 'bun-v1.0.0') }
  let(:zip_entry) { instance_double(Zip::Entry, name: 'bun') }
  let(:zip_file) { instance_double(Zip::File) }
  let(:temp_file) { instance_double(Tempfile, path: '/tmp/fake.zip', unlink: true) }

  before do
    allow(BuildHelpers).to receive(:github_client).and_return(github_client)
    allow(github_client).to receive(:latest_release).and_return(release)

    # Pretend the file does not exist and just continue with the download
    allow(File).to receive(:exist?).and_return(false)

    allow(Down).to receive(:download).and_return(temp_file)
    allow(Zip::File).to receive(:open).and_yield(zip_file)
    allow(zip_file).to receive(:find).and_return(zip_entry)
    allow(zip_entry).to receive(:extract)
    allow(FileUtils).to receive(:mkdir_p)
    allow(FileUtils).to receive(:chmod)
  end

  describe 'when downloading for current platform' do
    let(:downloader) { described_class.new }
    let(:platform) { Gem::Platform.local.to_s }
    let(:expected_binary_name) { platform.include?('mingw') ? 'bun.exe' : 'bun' }
    let(:expected_bun_platform) { BuildHelpers::PlatformManager.bun_platform_for(platform) }

    it 'downloads and extracts bun for current platform' do
      binary_path = downloader.download_for_current_platform

      expect(Down).to have_received(:download)
        .with("https://github.com/#{BuildHelpers::BUN_REPO}/releases/download/bun-v1.0.0/bun-#{expected_bun_platform}.zip")
      expect(binary_path).to eq("lib/bundlebun/vendor/bun/#{expected_binary_name}")
    end

    it 'makes the binary executable' do
      binary_path = downloader.download_for_current_platform
      expect(FileUtils).to have_received(:chmod).with(0o755, binary_path)
    end

    it 'allows custom destination directory' do
      binary_path = downloader.download_for_current_platform(destination_dir: 'custom/path')
      expect(binary_path).to eq("custom/path/#{expected_binary_name}")
    end

    it 'creates destination directory if it does not exist' do
      downloader.download_for_current_platform(destination_dir: 'custom/path')
      expect(FileUtils).to have_received(:mkdir_p).with('custom/path')
    end
  end

  describe 'when downloading for a specified platform' do
    let(:downloader) { described_class.new('1.0.0') }

    it 'downloads and extracts bun for specified platform' do
      binary_path = downloader.download_for('x86_64-linux')

      expect(Down).to have_received(:download)
        .with("https://github.com/#{BuildHelpers::BUN_REPO}/releases/download/bun-v1.0.0/bun-linux-x64.zip")
      expect(binary_path).to eq('lib/bundlebun/vendor/bun/bun')
    end

    it 'handles Windows downloads correctly' do
      binary_path = downloader.download_for('x64-mingw-ucrt')

      expect(Down).to have_received(:download)
        .with("https://github.com/#{BuildHelpers::BUN_REPO}/releases/download/bun-v1.0.0/bun-windows-x64.zip")
      expect(binary_path).to eq('lib/bundlebun/vendor/bun/bun.exe')
    end
  end

  context 'when version is not specified' do
    it 'fetches latest version from GitHub' do
      described_class.new
      expect(github_client).to have_received(:latest_release)
        .with(BuildHelpers::BUN_REPO)
    end
  end

  context 'cleaning up' do
    let(:downloader) { described_class.new }
    let(:vendor_dir) { Bundlebun::Runner.full_directory }
    let(:test_files) do
      [
        File.join(vendor_dir, 'bun'),
        File.join(vendor_dir, 'bun.exe'),
        File.join(vendor_dir, 'bun-1.0.0.zip'),
        File.join(vendor_dir, 'some-other-file.txt')
      ]
    end

    before do
      allow(Dir).to receive(:glob)
        .with(File.join(vendor_dir, '{bun,bun.exe,bun*.zip}'))
        .and_return(test_files[0..2])

      test_files.each do |file|
        allow(File).to receive(:exist?).with(file).and_return(true)
        allow(File).to receive(:delete).with(file)
      end
    end

    it 'deletes all matching files in the vendor directory' do
      downloader.clear!

      # Should delete bun, bun.exe, and bun-1.0.0.zip
      expect(File).to have_received(:delete).with(test_files[0])
      expect(File).to have_received(:delete).with(test_files[1])
      expect(File).to have_received(:delete).with(test_files[2])

      # Should not delete other files
      expect(File).not_to have_received(:delete).with(test_files[3])
    end
  end
end
