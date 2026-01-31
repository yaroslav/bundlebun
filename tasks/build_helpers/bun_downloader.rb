# frozen_string_literal: true

require 'down'
require 'zip'
require 'fileutils'

module BuildHelpers
  class BunDownloader
    def initialize(version = nil)
      @version = version || fetch_latest_version
    end

    def download_for_current_platform(destination_dir: Bundlebun::Runner.relative_directory)
      platform = Gem::Platform.local.to_s
      download_for(platform, destination_dir: destination_dir)
    end

    def download_for(platform, destination_dir: Bundlebun::Runner.relative_directory)
      bun_platform = PlatformManager.bun_platform_for(platform)
      binary_name = PlatformManager.binary_name_for(platform)

      binary_path = File.join(destination_dir, binary_name)

      unless File.exist?(binary_path)
        FileUtils.mkdir_p(destination_dir)
        download_and_extract(bun_platform, binary_path)
        FileUtils.chmod(0o755, binary_path)
      end

      binary_path
    end

    def clear!
      Dir.glob(File.join(Bundlebun::Runner.full_directory, '{bun,bun.exe,bun*.zip}')).each do |file|
        File.delete(file) if File.exist?(file)
      end
    end

    private

    def download_and_extract(bun_platform, binary_path)
      filename = "bun-#{bun_platform}.zip"
      url = "https://github.com/#{BUN_REPO}/releases/download/bun-v#{@version}/#{filename}"

      zip_file = Down.download(url)
      Zip::File.open(zip_file.path) do |zip|
        entry = zip.find { |e| e.name.end_with?(File.basename(binary_path)) }
        entry.extract(binary_path)
      end
    ensure
      zip_file&.unlink
    end

    def fetch_latest_version
      BuildHelpers.github_client.latest_release(BUN_REPO).tag_name.delete_prefix('bun-v')
    end
  end
end
