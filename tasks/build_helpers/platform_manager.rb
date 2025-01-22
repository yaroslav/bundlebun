# frozen_string_literal: true

module BuildHelpers
  class PlatformManager
    # RubyGems => Bun platforms
    PLATFORM_MAPPING = {
      'x86_64-linux' => 'linux-x64',
      'aarch64-linux' => 'linux-aarch64',
      'arm64-darwin' => 'darwin-aarch64',
      'x86_64-darwin' => 'darwin-x64',
      'x64-mingw-ucrt' => 'windows-x64-baseline'
    }.freeze

    def self.bun_platform_for(ruby_platform)
      platform = Gem::Platform.new(ruby_platform)
      match = PLATFORM_MAPPING.keys.find { |k| platform =~ Gem::Platform.new(k) }
      PLATFORM_MAPPING[match]
    end

    def self.binary_name_for(platform)
      platform.include?('mingw') ? 'bun.exe' : 'bun'
    end
  end
end
