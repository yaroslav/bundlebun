# frozen_string_literal: true

require 'rubygems/package'

module BuildHelpers
  class GemBuilder
    class BuildError < StandardError; end

    def initialize(gemspec)
      @gemspec = gemspec
      @failed_platforms = []
    end

    def build_for_all_platforms
      built_gems = []

      PlatformManager::PLATFORM_MAPPING.each_key do |platform|
        puts "Building for #{platform}..."
        gem_file = build_platform(platform)
        built_gems << gem_file if gem_file
      end

      raise_error_if_any_failed
      built_gems
    end

    private

    # Each platform's gem is built inside its own sandbox directory under tmp/.
    # The sandbox is populated with copies of the gem source files plus a
    # freshly-downloaded binary for the target platform, so the host's
    # `lib/bundlebun/vendor/bun/bun` is never touched during a build.
    def build_platform(platform)
      sandbox = sandbox_dir(platform)
      prepare_sandbox(sandbox)
      binary_path = download_binary(platform, sandbox)
      return handle_missing_binary(platform) unless binary_path

      build_gem_in_sandbox(platform, sandbox)
    rescue Down::NotFound, Errno::ENOENT => e
      handle_download_error(platform, e)
      nil
    ensure
      FileUtils.rm_rf(sandbox)
    end

    def sandbox_dir(platform)
      "tmp/build_#{platform}"
    end

    def prepare_sandbox(sandbox)
      FileUtils.rm_rf(sandbox)
      FileUtils.mkdir_p(sandbox)
      @gemspec.files.each do |relative_path|
        # Skip the bun binary specifically: the platform-correct copy is
        # downloaded fresh into the sandbox by `download_binary`.
        next if vendor_binary_files.include?(relative_path)

        src = File.expand_path(relative_path)
        next unless File.file?(src)

        dst = File.join(sandbox, relative_path)
        FileUtils.mkdir_p(File.dirname(dst))
        FileUtils.cp(src, dst)
      end
    end

    def vendor_binary_files
      vendor = Bundlebun::Runner.relative_directory
      [File.join(vendor, 'bun'), File.join(vendor, 'bun.exe')]
    end

    def download_binary(platform, sandbox)
      bun_version = extract_bun_version
      destination_dir = File.join(sandbox, Bundlebun::Runner.relative_directory)
      downloader = BunDownloader.new(bun_version)
      binary_path = downloader.download_for(platform, destination_dir: destination_dir)

      return unless binary_path && File.exist?(binary_path)

      binary_path
    end

    def build_gem_in_sandbox(platform, sandbox)
      repo_root = Dir.pwd
      binary_relative = File.join(Bundlebun::Runner.relative_directory, PlatformManager.binary_name_for(platform))

      Dir.chdir(sandbox) do
        platform_gemspec = @gemspec.dup
        platform_gemspec.platform = platform
        files = @gemspec.files.dup
        files << binary_relative unless files.include?(binary_relative)
        platform_gemspec.files = files

        gem_filename = Gem::Package.build(platform_gemspec)
        FileUtils.mv(gem_filename, repo_root)
        File.basename(gem_filename)
      end
    end

    def handle_missing_binary(platform)
      handle_download_error(platform, 'Binary not found after download')
      nil
    end

    def handle_download_error(platform, error)
      @failed_platforms << platform
      message = error.respond_to?(:message) ? error.message : error.to_s
      warn "Failed to build for #{platform}: #{message}"
    end

    def raise_error_if_any_failed
      return unless @failed_platforms.any?

      platforms = @failed_platforms.join(', ')
      raise BuildError, "Failed to download Bun for platforms: #{platforms}"
    end

    def extract_bun_version
      @gemspec.version.to_s.split('.').drop(3).join('.')
    end
  end
end
