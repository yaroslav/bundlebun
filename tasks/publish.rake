# frozen_string_literal: true

namespace :bundlebun do
  desc 'Create GitHub release and publish gems to RubyGems'
  task :publish do
    version_checker = BuildHelpers::BunVersion.new
    bun_version = version_checker.latest_bun_repo_version
    gem_version = "#{Bundlebun::VERSION}.#{bun_version}"

    BuildHelpers::GemPublisher.new(gem_version).publish
  end
end
