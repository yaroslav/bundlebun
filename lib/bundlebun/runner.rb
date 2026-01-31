# frozen_string_literal: true

module Bundlebun
  # {Runner} is the class that bundlebun uses to run the bundled Bun executable.
  #
  # bundlebun provides two ways to run Bun:
  #
  # - {.call} (also available as {.exec}): Replaces the current Ruby process with Bun. This is the default.
  #
  # - {.system}: Runs Bun as a subprocess and returns control to Ruby.
  #   Use this when you need to continue executing Ruby code after Bun finishes.
  #
  # @see Bundlebun
  #
  # @example Running Bun (replaces process, never returns)
  #   Bundlebun.('install')
  #   Bundlebun.call('outdated')
  #   Bundlebun.call(['add', 'postcss'])
  #
  # @example Running Bun as subprocess (returns to Ruby)
  #   if Bundlebun.system('install')
  #     puts 'Dependencies installed!'
  #   end
  class Runner
    BINSTUB_PATH = 'bin/bun'
    RELATIVE_DIRECTORY = 'lib/bundlebun/vendor/bun'

    class << self
      # Replaces the current Ruby process with Bun.
      #
      # @param arguments [String, Array<String>] Command arguments to pass to Bun
      # @return [void] This method never returns
      #
      # @example In a binstub (bin/bun)
      #   #!/usr/bin/env ruby
      #   require 'bundlebun'
      #   Bundlebun.exec(ARGV)
      #
      # @see .call
      # @see .system
      def exec(...)
        new(...).exec
      end

      # Replaces the current Ruby process with Bun. Alias for {.exec}.
      # Also available via the +.()+ shorthand syntax.
      #
      # @param arguments [String, Array<String>] Command arguments to pass to Bun
      # @return [void] This method never returns
      #
      # @example Basic usage
      #   Bundlebun.call('outdated')
      #   Bundlebun.call(['add', 'postcss'])
      #
      # @example Using the .() shorthand
      #   Bundlebun.('install')
      #
      # @see .exec
      # @see .system
      def call(...)
        exec(...)
      end

      # Runs Bun as a subprocess and returns control to Ruby.
      #
      # Unlike {.call} and {.exec}, this method does not replace the current process.
      # Use this when you need to run Bun and then continue executing Ruby code.
      #
      # @param arguments [String, Array<String>] Command arguments to pass to Bun
      # @return [Boolean, nil] +true+ if Bun exited successfully (status 0),
      #   +false+ if it exited with an error, +nil+ if execution failed
      #
      # @example Run install and check result
      #   if Bundlebun.system('install')
      #     puts 'Dependencies installed!'
      #   else
      #     puts 'Installation failed'
      #   end
      #
      # @see .call
      # @see .exec
      def system(...)
        new(...).system
      end

      # A relative path to binstub that bundlebun usually generates with installation Rake tasks.
      #
      # For Windows, the binstub path will return the `bun.cmd` wrapper.
      #
      # @return [String]
      def binstub_path
        Bundlebun::Platform.windows? ? "#{BINSTUB_PATH}.cmd" : BINSTUB_PATH
      end

      # A full path to binstub that bundlebun usually generates with installation Rake tasks.
      #
      # For Windows, that will use the `bun.cmd` wrapper.
      #
      # @return [String]
      def full_binstub_path
        File.expand_path(binstub_path)
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
        return @full_directory if defined?(@full_directory)

        @full_directory = File.expand_path("../../#{relative_directory}", __dir__)
      end

      # A full path to the bundled Bun binary we run
      # (includes `.exe` on Windows).
      #
      # @return [String]
      def binary_path
        return @binary_path if defined?(@binary_path)

        executable = "bun#{".exe" if Bundlebun::Platform.windows?}"
        @binary_path = File.join(full_directory, executable)
      end

      # Does the bundled Bun binary exist?
      #
      # @return [Boolean]
      def binary_path_exist?
        File.exist?(binary_path)
      end

      # Returns the preferred way to run Bun when bundlebun is installed.
      #
      # If the binstub is installed (see binstub_path), use the full path to binstub.
      # If not, use the full binary path for the bundled executable (binary_path).
      #
      # @return [String]
      def binstub_or_binary_path
        binstub_exist? ? full_binstub_path : binary_path
      end

      # Does the binstub exist?
      #
      # @return [Boolean]
      def binstub_exist?
        File.exist?(binstub_path)
      end
    end

    # Initialize the {Runner} with arguments to run the Bun runtime later.
    #
    # @param arguments [String, Array<String>] Command arguments to pass to Bun
    #
    # @example String as an argument
    #   Bundlebun::Runner.new('--version')
    #
    # @example Array of strings as an argument
    #   Bundlebun::Runner.new(['add', 'postcss'])
    #
    # @see #system
    # @see #exec
    def initialize(arguments = '')
      @arguments = arguments
    end

    # Replaces the current Ruby process with Bun.
    # This is the default behavior.
    #
    # @return [void] This method never returns
    #
    # @example
    #   runner = Bundlebun::Runner.new(ARGV)
    #   runner.exec  # Ruby process ends here, Bun takes over
    #
    # @see #system
    def exec
      check_executable!
      Kernel.exec(command)
    end

    # Replaces the current Ruby process with Bun. Alias for {#exec}.
    #
    # @return [void] This method never returns
    #
    # @see #exec
    def call
      exec
    end

    # Runs Bun as a subprocess and returns control to Ruby.
    #
    # Unlike {#call} and {#exec}, this method does not replace the current process.
    # Use this when you need to run Bun and then continue executing Ruby code.
    #
    # @return [Boolean, nil] +true+ if Bun exited successfully (status 0),
    #   +false+ if it exited with an error, +nil+ if execution failed
    #
    # @example
    #   runner = Bundlebun::Runner.new('install')
    #   if runner.system
    #     puts 'Dependencies installed!'
    #   end
    #
    # @see #exec
    def system
      check_executable!
      Kernel.system(command)
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
