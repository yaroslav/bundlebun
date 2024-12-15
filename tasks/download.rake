# frozen_string_literal: true

namespace :bundlebun do
  desc 'Download bun binary for current platform'
  task :download do
    binary_path = BuildHelpers::BunDownloader.new.download_for_current_platform
    puts "Bun binary downloaded to: #{File.expand_path(binary_path)}"
  end
end
