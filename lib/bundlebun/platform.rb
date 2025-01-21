# frozen_string_literal: true

module Bundlebun
  # Platform contains a set of helpers to deal with platform detection.
  # Mostly, to see if we are running on Windows.
  class Platform
    class << self
      # Are we running on Windows?
      #
      # @return [Boolean]
      def windows?
        return @windows if defined?(@windows)

        @windows = defined?(RbConfig) && defined?(RbConfig::CONFIG) &&
          RbConfig::CONFIG['host_os'].match?(/mswin|mingw|cygwin/)
      end
    end
  end
end
