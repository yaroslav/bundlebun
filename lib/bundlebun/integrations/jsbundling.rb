# frozen_string_literal: true

module Bundlebun
  module Integrations
    # A Bundlebun integration for [jsbundling-rails](https://github.com/rails/jsbundling-rails).
    #
    # It's hard to override those methods on the fly, and a Rails initializer in the
    # target project also does not seem to work, so we have to create a dummy task
    # in the actual Rails project, and patch the helper module Tasks from there.
    #
    # When installed, makes it run a bundled Bun runtime for packing tasks.
    #
    # @see https://github.com/rails/jsbundling-rails
    # @see https://github.com/rails/jsbundling-rails/blob/main/lib/tasks/jsbundling/build.rake
    module Jsbundling
      # Patches the existing module.
      #
      # Call this after everything is loaded and required.
      # For a Rails application, a good place is... not an initializer,
      # but some code that can be run in a Rake task. Like a custom Rake task
      # in `lib/tasks`.
      #
      # See the documentation for more info on installation Rake tasks.
      #
      # @example
      #   Bundlebun::Integrations::Jsbundling.bun!
      def self.bun!
        return unless defined?(::Jsbundling::Tasks)

        ::Jsbundling::Tasks.prepend(self::Tasks)
      end

      # A monkeypatch for tasks that are defined in the original
      # Rake task
      #
      # @see https://github.com/rails/jsbundling-rails/blob/main/lib/tasks/jsbundling/build.rake
      module Tasks
        extend self

        def install_command
          "#{Bundlebun::Runner.binstub_or_binary_path} install"
        end

        def build_command
          "#{Bundlebun::Runner.binstub_or_binary_path} run --bun build"
        end
      end
    end
  end
end
