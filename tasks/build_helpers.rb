# frozen_string_literal: true

require_relative '../lib/bundlebun'
require 'octokit'

module BuildHelpers
  BUN_REPO = 'oven-sh/bun'
  GEM_REPO = 'yaroslav/bundlebun'

  def self.github_client
    @github_client ||= Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])
  end
end

require_relative 'build_helpers/platform_manager'
require_relative 'build_helpers/bun_downloader'
require_relative 'build_helpers/bun_version'
require_relative 'build_helpers/gem_builder'
require_relative 'build_helpers/gem_publisher'
