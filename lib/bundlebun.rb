# frozen_string_literal: true

require 'zeitwerk'

# bundlebun bundles Bun[https://bun.sh], a fast JavaScript runtime, package manager
# and builder, with your Ruby and Rails applications.
# No Docker, devcontainers, <tt>curl | sh</tt>, or <tt>brew</tt> needed.
#
# bundlebun includes binary distributions of Bun for each of the supported
# platforms (macOS, Linux, Windows) and architectures.
module Bundlebun
  class << self
    # Runs the Bun runtime with parameters (can be String or Array of strings).
    #
    # A shortcut for Bundlebun::Runner.call.
    #
    # Example:
    #
    #   Bundlebun.call('--version') # => `bun --version`
    #   Bundlebun.call(['add', 'postcss']) => `bun add postcss`
    #
    # Returns error status <tt>127</tt> if the executable does not exist.
    def call(...)
      Runner.call(...)
    end

    def loader # :nodoc:
      @loader ||= Zeitwerk::Loader.for_gem.tap do |loader|
        loader.ignore("#{__dir__}/tasks")
        loader.ignore("#{__dir__}/bundlebun/vendor")
        loader.ignore("#{__dir__}/templates")

        loader.inflector.inflect('execjs' => 'ExecJS')

        loader.setup
      end
    end

    def load_tasks # :nodoc:
      Dir[File.expand_path('tasks/*.rake', __dir__)].each { |task| load task }
    end

    def bun = 'Bun' # :nodoc:
    alias_method :bun?, :bun
    alias_method :bun!, :bun
  end
end

Bundlebun.loader

Bundlebun.load_tasks if defined?(Rake)
