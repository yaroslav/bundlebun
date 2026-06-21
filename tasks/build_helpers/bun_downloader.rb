# frozen_string_literal: true

require 'down'
require 'zip'
require 'fileutils'
require 'digest'

module BuildHelpers
  class BunDownloader
    # Raised when a downloaded archive's SHA256 does not match the checksum
    # Bun publishes in SHASUMS256.txt for the release. Raising aborts the build
    # so a tampered or corrupted binary is never extracted or packaged into a gem.
    class ChecksumError < StandardError; end

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

      puts "Downloading Bun #{@version} for #{platform} (#{bun_platform || "unmapped"})"

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
      release_url = "https://github.com/#{BUN_REPO}/releases/download/bun-v#{@version}"

      zip_file = Down.download("#{release_url}/#{filename}")
      verify_checksum!(zip_file.path, filename, release_url)

      Zip::File.open(zip_file.path) do |zip|
        entry = zip.find { |e| e.name.end_with?(File.basename(binary_path)) }
        entry.extract(binary_path)
      end
    ensure
      zip_file&.unlink
    end

    # Verifies the downloaded archive against the SHA256 that Bun publishes in
    # the release's SHASUMS256.txt. Runs before extraction and raises on
    # mismatch (or if no checksum is published for the file), so a bad binary
    # never gets extracted or packaged.
    def verify_checksum!(zip_path, filename, release_url)
      expected = published_checksums(release_url)[filename]
      raise ChecksumError, "No SHA256 published for #{filename} in SHASUMS256.txt" unless expected

      actual = Digest::SHA256.file(zip_path).hexdigest
      unless actual.casecmp?(expected)
        raise ChecksumError, "SHA256 mismatch for #{filename}: expected #{expected}, got #{actual}"
      end

      puts "Verified SHA256 for #{filename}"
    end

    # Downloads the release's SHASUMS256.txt and parses it into a
    # { "bun-linux-x64.zip" => "<sha256>", ... } map.
    def published_checksums(release_url)
      sums_file = Down.download("#{release_url}/SHASUMS256.txt")
      parse_checksums(File.read(sums_file.path))
    ensure
      sums_file&.unlink
    end

    # Parses `sha256sum`-style lines ("<hash>  <filename>"), tolerating the
    # optional `*` binary-mode marker before the filename.
    def parse_checksums(content)
      content.each_line.with_object({}) do |line, sums|
        hash, name = line.strip.split(/\s+/, 2)
        next if hash.to_s.empty? || name.to_s.empty?

        sums[name.delete_prefix('*')] = hash
      end
    end

    def fetch_latest_version
      BuildHelpers.github_client.latest_release(BUN_REPO).tag_name.delete_prefix('bun-v')
    end
  end
end
