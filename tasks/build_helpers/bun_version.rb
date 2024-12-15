# frozen_string_literal: true

require 'octokit'

module BuildHelpers
  class BunVersion
    def initialize
      @github = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])
    end

    def latest_bun_repo_version
      @github.latest_release(BUN_REPO).tag_name.delete_prefix('bun-v')
    end

    def latest_gem_version
      @github.latest_release(GEM_REPO).tag_name.delete_prefix('bundlebun-v')
    rescue Octokit::NotFound
      # If there were no releases
      "#{Bundlebun::VERSION}.0.0.0"
    end

    def latest_bun_gem_version
      latest_gem_version.split('.').drop(3).join('.')
    end

    def version_changed?
      bun_ver = latest_bun_repo_version.split('.')
      our_ver = latest_bun_gem_version.split('.')

      bun_ver != our_ver
    end
  end
end
