# frozen_string_literal: true

namespace :bundlebun do
  desc 'Check for new Bun version'
  task :check_version do
    version_checker = BuildHelpers::BunVersion.new

    if version_checker.version_changed?
      puts "New version detected: #{version_checker.latest_bun_repo_version} vs. #{version_checker.latest_bun_gem_version}"
      exit 0
    else
      puts 'No new version available'
      exit 1
    end
  end
end
