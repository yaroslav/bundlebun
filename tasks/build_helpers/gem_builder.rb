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

    def build_platform(platform)
      prepare_directories(platform)
      binary_path, executable = download_binary(platform)
      return handle_missing_binary(platform) unless binary_path

      build_gem_for_platform(platform, binary_path)
    rescue Down::NotFound, Errno::ENOENT => e
      handle_download_error(platform, e)
      nil
    ensure
      cleanup_platform_binary(executable) if executable
      cleanup_build_directory(platform)
    end

    def prepare_directories(platform)
      build_dir = "tmp/build_#{platform}"
      FileUtils.mkdir_p([build_dir, Bundlebun::Runner.relative_directory])
    end

    def download_binary(platform)
      bun_version = extract_bun_version
      downloader = BunDownloader.new(bun_version)
      binary_path = downloader.download_for(platform)

      return unless binary_path && File.exist?(binary_path)

      [binary_path, File.basename(binary_path)]
    end

    def build_gem_for_platform(platform, binary_path)
      platform_gemspec = @gemspec.dup
      platform_gemspec.platform = platform
      platform_gemspec.files = @gemspec.files.dup + [binary_path]
      Gem::Package.build(platform_gemspec)
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

    def cleanup_build_directory(platform)
      FileUtils.rm_rf("tmp/build_#{platform}")
    end

    def cleanup_platform_binary(executable)
      FileUtils.rm_f(File.join(Bundlebun::Runner.relative_directory, executable))
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
