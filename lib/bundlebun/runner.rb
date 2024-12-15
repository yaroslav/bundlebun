# frozen_string_literal: true

module Bundlebun
  # Runner is the class that bundlebun uses to run the bundled Bun executable.
  #
  # See Bundlebun.
  class Runner
    BINSTUB_PATH = 'bin/bun' # :nodoc:
    RELATIVE_DIRECTORY = 'lib/bundlebun/vendor/bun' # :nodoc:

    class << self
      # Runs the Bun runtime with parameters (can be String or Array of strings).
      #
      # See Bundlebun::Runner.new, Bundlebun::Runner.call.
      #
      # Example:
      #
      #   Bundlebun.call('--version')
      #   Bundlebun.call(['add', 'postcss'])
      #
      # Returns error status <tt>127</tt> if the executable does not exist.
      def call(...)
        new(...).call
      end

      # A relative path to binstub bundlebun usually generates with installation Rake tasks.
      def binstub_path
        BINSTUB_PATH
      end

      # A relative directory path to the bundled Bun executable from the root of the gem.
      def relative_directory
        RELATIVE_DIRECTORY
      end

      # A full directory path to the bundled Bun executable from the root of the gem.
      def full_directory
        File.expand_path("../../#{relative_directory}", __dir__)
      end

      # A full path to the bundled Bun binary we run.
      def binary_path
        executable = "bun#{RUBY_PLATFORM.match?(/mingw|mswin/) ? ".exe" : ""}"
        File.join(full_directory, executable)
      end

      # Does the bundled Bun binary exist?
      def binary_path_exist?
        File.exist?(binary_path)
      end

      # Returns the preferred way to run Bun when bundlebun is installed.
      #
      # If the binstub is installed (see binstub_path), use the binstub.
      # If not, use the full binary path for the bundled executable (binary_path).
      def binstub_or_binary_path
        binstub_exist? ? binstub_path : binary_path
      end

      # Does the binstub exist?
      def binstub_exist?
        File.exist?(binstub_path)
      end
    end

    # Intialize the runner with arguments to run the Bun runtime later via call.
    #
    # Arguments can be a String or an Array of strings.
    #
    # Example:
    #
    #   Bundlebun::Runner.new('--version')
    #   Bundlebun::Runner.new(['install', 'postcss'])
    #
    # Returns error status <tt>127</tt> if the executable does not exist.
    def initialize(arguments = '')
      @arguments = arguments
    end

    # Runs the Bun executable with previously specified arguments.
    #
    # Returns error status <tt>127</tt> if the executable does not exist.
    #
    # Example:
    #
    #   r = Bundlebun::Runner.new('--version')
    #   r.call!
    #
    # Check other methods of Bundlebun::Runner to see how we determine what to run exactly.
    def call
      check_executable!
      exec(command)
    end

    private

    attr_reader :arguments

    def check_executable!
      return if self.class.binary_path_exist?

      Kernel.warn "Unable to run Bun: executable not found at #{self.class.binary_path}"
      Kernel.exit 127
    end

    def command
      [self.class.binary_path, *arguments].join(' ').strip
    end
  end
end
