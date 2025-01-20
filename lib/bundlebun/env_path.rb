# frozen_string_literal: true

module Bundlebun
  # EnvPath exists to help prepend the bun binary path to the system PATH,
  # in order to make it easier for other gems and utilities to "see" the
  # existing bun executable without the need to monkey-patch tools that already
  # support Bun.
  # This approach only works when the bundlebun gem is already loaded, which
  # is not always the case, unfortunately.
  class EnvPath
    class << self
      # Returns the current system PATH.
      #
      # @return [String] The system PATH
      def path
        ENV['PATH']
      end

      # Sets the system PATH to a new value (_not_ prepends the value).
      #
      # @param new_path [String] The new system PATH
      def path=(new_path)
        ENV['PATH'] = new_path
      end

      # Prepends a new path to the system PATH.
      # Makes sure to use different separators for different platforms.
      #
      # @param new_path [String] The new path to prepend
      # @return [String] The new system PATH
      def prepend(new_path)
        return if new_path.nil? || new_path.empty?

        path_to_check = on_windows? ? path.downcase : path
        check_path = on_windows? ? new_path.downcase : new_path
        return if path_to_check.start_with?(check_path)

        self.path = "#{new_path}#{separator}#{path}"
        path
      end

      # The `PATH` separator for the current platform (`:` or `;`)
      #
      # @return [String] The separator character
      def separator
        return @separator if defined?(@separator)

        @separator = on_windows? ? ';' : ':'
      end

      # Are we running on Windows?
      #
      # @return [Boolean]
      def on_windows?
        return @on_windows if defined?(@on_windows)

        @on_windows = defined?(RbConfig) && defined?(RbConfig::CONFIG) &&
          RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
      end
    end
  end
end
