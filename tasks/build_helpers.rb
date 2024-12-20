# frozen_string_literal: true

require_relative '../lib/bundlebun'

module BuildHelpers
  BUN_REPO = 'oven-sh/bun'
  GEM_REPO = 'yaroslav/bundlebun'
end

require_relative 'build_helpers/platform_manager'
require_relative 'build_helpers/bun_downloader'
require_relative 'build_helpers/bun_version'
require_relative 'build_helpers/gem_builder'
require_relative 'build_helpers/gem_publisher'
