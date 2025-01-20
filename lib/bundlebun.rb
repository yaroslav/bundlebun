# frozen_string_literal: true

require 'zeitwerk'

# bundlebun bundles [Bun](https://bun.sh), a fast JavaScript runtime, package manager
# and builder, with your Ruby and Rails applications.
# No Docker, devcontainers, `curl | sh`, or `brew` needed.
#
# bundlebun includes binary distributions of Bun for each of the supported
# platforms (macOS, Linux, Windows) and architectures.
#
# @see Bundlebun::Runner
# @see Bundlebun::Integrations
module Bundlebun
  class << self
    # Runs the Bun runtime with parameters.
    #
    # A shortcut for {Bundlebun::Runner.call}.
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
    # @see Bundlebun::Runner.call
    def call(...)
      Runner.call(...)
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

    def prepend_to_path # @private
      EnvPath.prepend(Runner.full_directory)
    end

    def load_tasks # @private
      Dir[File.expand_path('tasks/*.rake', __dir__)].each { |task| load task }
    end

    def load_integrations # @private
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
