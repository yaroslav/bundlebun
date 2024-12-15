# frozen_string_literal: true

module BuildHelpers
  class GemPublisher
    class PublishError < StandardError; end

    def initialize(version)
      @version = version
      @github_client = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])
      @version_checker = BunVersion.new
      @tag = "bundlebun-v#{@version}"
    end

    def publish
      validate_environment!
      validate_gems_exist!

      create_github_release
      publish_to_rubygems
    end

    private

    def validate_environment!
      return if ENV['GEM_HOST_API_KEY']

      raise PublishError, 'GEM_HOST_API_KEY not provided'
    end

    def validate_gems_exist!
      return if File.exist?('built_gems.txt') && !gem_files.empty?

      raise PublishError, 'No built_gems.txt found'
    end

    def gem_files
      @gem_files ||= File.readlines('built_gems.txt').map(&:strip)
    end

    def create_github_release
      release_notes = generate_release_notes

      release = @github_client.create_release(
        GEM_REPO,
        @tag,
        name: "bundlebun v#{@version}",
        body: release_notes,
        draft: false,
        prerelease: false,
        target_commitish: 'main'
      )

      upload_gem_files(release)
    rescue Octokit::Error => e
      raise PublishError, "Failed to create GitHub release: #{e.message}"
    end

    def upload_gem_files(release)
      gem_files.each do |gem_file|
        @github_client.upload_asset(
          release.url,
          gem_file,
          content_type: 'application/x-ruby-gem'
        )
      end
    end

    def generate_release_notes
      bun_version = @version_checker.latest_bun_repo_version
      <<~NOTES
        bundlebun #{@version}, includes a binary distribution of [Bun #{bun_version}](https://github.com/#{BuildHelpers::BUN_REPO}/releases/tag/bun-v#{bun_version}). Built for: #{PlatformManager::PLATFORM_MAPPING.keys.join(", ")}.

        Changelog: [CHANGELOG](https://github.com/#{BuildHelpers::GEM_REPO}/blob/main/CHANGELOG.md).

        See [README](https://github.com/#{BuildHelpers::GEM_REPO}) for installation instructions and documentation. See [LICENSE](https://github.com/#{BuildHelpers::GEM_REPO}/blob/main/LICENSE.txt) for licensing information.

        ### Quick installation

        ```bash
        bundle add bundlebun

        rake bun:install
        ```
      NOTES
    end

    def publish_to_rubygems
      gem_files.each do |gem_file|
        system("gem push #{gem_file} --key #{ENV["GEM_HOST_API_KEY"]}", exception: true)
      end
    rescue => e
      raise PublishError, "Failed to publish to RubyGems: #{e.message}"
    end
  end
end
