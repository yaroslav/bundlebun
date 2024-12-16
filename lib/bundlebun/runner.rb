# frozen_string_literal: true

module Bundlebun
  # {Runner} is the class that bundlebun uses to run the bundled Bun executable.
  #
  # @see Bundlebun
  class Runner
    BINSTUB_PATH = 'bin/bun'
    RELATIVE_DIRECTORY = 'lib/bundlebun/vendor/bun'

    class << self
      # Runs the Bun runtime with parameters.
      #
      # A wrapper for {Bundlebun::Runner.new}, {Bundlebun::Runner.call}.
      #
      # @param arguments [String, Array<String>] Command arguments to pass to Bun
      # @return [Integer] Exit status code (`127` if executable not found)
      #
      # @example String as an argument
      #   Bundlebun.call('--version') # => `bun --version`
      #
      # @example Array of strings as an argument
      #   Bundlebun.call(['add', 'postcss']) # => `bun add postcss`
      #
      # @see Bundlebun::Runner.new
      # @see Bundlebun::Runner#call
      def call(...)
        new(...).call
      end

      # A relative path to binstub that bundlebun usually generates with installation Rake tasks.
      #
      # @return [String]
      def binstub_path
        BINSTUB_PATH
      end

      # A relative directory path to the bundled Bun executable from the root of the gem.
      #
      # @return [String]
      def relative_directory
        RELATIVE_DIRECTORY
      end

      # A full directory path to the bundled Bun executable from the root of the gem.
      #
      # @return [String]
      def full_directory
        File.expand_path("../../#{relative_directory}", __dir__)
      end

      # A full path to the bundled Bun binary we run
      # (includes `.exe` on Windows).
      #
      # @return [String]
      def binary_path
        executable = "bun#{RUBY_PLATFORM.match?(/mingw|mswin/) ? ".exe" : ""}"
        File.join(full_directory, executable)
      end

      # Does the bundled Bun binary exist?
      #
      # @return [Boolean]
      def binary_path_exist?
        File.exist?(binary_path)
      end

      # Returns the preferred way to run Bun when bundlebun is installed.
      #
      # If the binstub is installed (see binstub_path), use the binstub.
      # If not, use the full binary path for the bundled executable (binary_path).
      #
      # @return [String]
      def binstub_or_binary_path
        binstub_exist? ? binstub_path : binary_path
      end

      # Does the binstub exist?
      #
      # @return [Boolean]
      def binstub_exist?
        File.exist?(binstub_path)
      end
    end

    # Intialize the {Runner} with arguments to run the Bun runtime later via #call.
    #
    # @param arguments [String, Array<String>] Command arguments to pass to Bun
    #
    # @example String as an argument
    #   Bundlebun::Runner.new('--version') # => `bun --version`
    #
    # @example Array of strings as an argument
    #   Bundlebun::Runner.new(['add', 'postcss']) # => `bun add postcss`
    #
    # @see Bundlebun::Runner#call
    def initialize(arguments = '')
      @arguments = arguments
    end

    # Runs the Bun executable with previously specified arguments.
    #
    # Check other methods of {Bundlebun::Runner} to see how we determine what to run exactly.
    #
    # @return [Integer] Exit status code (`127` if executable not found)
    #
    # @example
    #   b = Bundlebun::Runner.new('--version')
    #   b.call
    #
    # @see Bundlebun::Runner
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
