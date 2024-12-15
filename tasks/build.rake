# frozen_string_literal: true

require 'octokit'

namespace :bundlebun do
  desc 'Build gem for all platforms'
  task :build do
    gemspec = Gem::Specification.load('bundlebun.gemspec')

    version_checker = BuildHelpers::BunVersion.new
    bun_version = version_checker.latest_bun_repo_version

    gemspec.version = "#{Bundlebun::VERSION}.#{bun_version}"
    puts "Building version #{gemspec.version}\n\n"

    builder = BuildHelpers::GemBuilder.new(gemspec)
    built_gems = builder.build_for_all_platforms

    File.write('built_gems.txt', built_gems.join("\n"))
    exit(built_gems.empty? ? 1 : 0)
  end
end
