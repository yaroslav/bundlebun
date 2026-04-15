# frozen_string_literal: true

module BuildHelpers
  class PlatformManager
    # RubyGems => Bun platforms.
    # Order matters: musl variants must come before their bare-linux
    # counterparts so #bun_platform_for picks the most specific match first.
    PLATFORM_MAPPING = {
      'x86_64-linux-musl' => 'linux-x64-musl',
      'x86_64-linux' => 'linux-x64',
      'aarch64-linux-musl' => 'linux-aarch64-musl',
      'aarch64-linux' => 'linux-aarch64',
      'arm64-darwin' => 'darwin-aarch64',
      'x86_64-darwin' => 'darwin-x64',
      'x64-mingw-ucrt' => 'windows-x64'
    }.freeze

    def self.bun_platform_for(ruby_platform)
      platform = Gem::Platform.new(ruby_platform)
      match = PLATFORM_MAPPING.keys.find { |k| Gem::Platform.new(k) =~ platform }
      PLATFORM_MAPPING[match]
    end

    def self.binary_name_for(platform)
      platform.include?('mingw') ? 'bun.exe' : 'bun'
    end
  end
end
