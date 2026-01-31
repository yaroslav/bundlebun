# frozen_string_literal: true

require 'zeitwerk'

# bundlebun bundles [Bun](https://bun.sh), a fast JavaScript runtime, package manager
# and builder, with your Ruby and Rails applications.
# No Docker, devcontainers, `curl | sh`, or `brew` needed.
#
# bundlebun includes binary distributions of Bun for each of the supported
# platforms (macOS, Linux, Windows) and architectures.
#
# bundlebun provides two ways to run Bun:
#
# - {.call} (also available as {.exec}): Replaces the current Ruby process with Bun. The default.
#
# - {.system}: Runs Bun as a subprocess and returns control to Ruby.
#   Use this when you need to continue executing Ruby code after Bun finishes.
#
# @see Bundlebun::Runner
# @see Bundlebun::Integrations
#
# @example Running Bun (replaces process, never returns)
#   Bundlebun.('install')                # .() shorthand syntax
#   Bundlebun.call('outdated')
#   Bundlebun.call(['add', 'postcss'])
#
# @example Running Bun as subprocess (returns to Ruby)
#   if Bundlebun.system('install')
#     puts 'Dependencies installed!'
#   end
module Bundlebun
  class << self
    # Replaces the current Ruby process with Bun.
    #
    # This is the default way to run Bun. The Ruby process is replaced by Bun
    # and never returns. Also available via the +.()+ shorthand syntax.
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
    #   Bundlebun.(ARGV)
    #
    # @see .exec
    # @see .system
    # @see Bundlebun::Runner.call
    def call(...)
      Runner.call(...)
    end

    # Replaces the current Ruby process with Bun. Same as {.call}.
    #
    # @param arguments [String, Array<String>] Command arguments to pass to Bun
    # @return [void] This method never returns
    #
    # @see .call
    # @see Bundlebun::Runner.exec
    def exec(...)
      Runner.exec(...)
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
    # @see Bundlebun::Runner.system
    def system(...)
      Runner.system(...)
    end

    def loader # @private
      @loader ||= Zeitwerk::Loader.for_gem.tap do |loader|
        loader.ignore("#{__dir__}/tasks")
        loader.ignore("#{__dir__}/bundlebun/vendor")
        loader.ignore("#{__dir__}/templates")

        loader.inflector.inflect('execjs' => 'ExecJS')

        loader.setup
      end
    end

    # Prepend the path to the bundled Bun executable to `PATH`.
    #
    # @see Bundlebun::Runner.full_directory
    def prepend_to_path
      EnvPath.prepend(Runner.full_directory)
    end

    # Load included Rake tasks (like `bun:install`).
    def load_tasks
      Dir[File.expand_path('tasks/*.rake', __dir__)].each { |task| load task }
    end

    # Detect and load all integrations (monkey-patches).
    #
    # @see Bundlebun::Integrations
    def load_integrations
      Integrations.bun!
    end

    def bun = 'Bun'
    alias_method :bun?, :bun
    alias_method :bun!, :bun
  end
end

Bundlebun.loader
Bundlebun.prepend_to_path
Bundlebun.load_tasks if defined?(Rake)
Bundlebun.load_integrations
