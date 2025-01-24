# frozen_string_literal: true

module Bundlebun
  module Integrations
    # A Bundlebun integration for [cssbundling-rails](https://github.com/rails/cssbundling-rails).
    #
    # It's hard to override those methods on the fly, and a Rails initializer in the
    # target project also does not seem to work, so we have to create a dummy task
    # in the actual Rails project, and patch the helper module Tasks from there.
    #
    # When installed, makes it run a bundled Bun runtime for packing tasks.
    #
    # @see https://github.com/rails/cssbundling-rails
    # @see https://github.com/rails/cssbundling-rails/blob/main/lib/tasks/cssbundling/build.rake
    module Cssbundling
      # Patches the existing module.
      #
      # Call this after everything is loaded and required.
      # For a Rails application, a good place is... _not_ an initializer,
      # but some code that can be run in a Rake task. Like a custom Rake task
      # in `lib/tasks`.
      #
      # See the documentation for more info on installation Rake tasks.
      #
      # @example
      #   Bundlebun::Integrations::Cssbundling.bun!
      def self.bun!
        return unless defined?(::Cssbundling::Tasks)

        ::Cssbundling::Tasks.prepend(self::Tasks)
      end

      # A monkeypatch for tasks that are defined in the original
      # Rake task
      #
      # @see https://github.com/rails/cssbundling-rails/blob/main/lib/tasks/cssbundling/build.rake
      module Tasks
        extend self

        def install_command
          "#{Bundlebun::Runner.binstub_or_binary_path} install"
        end

        def build_command
          cmd = "#{Bundlebun::Runner.binstub_or_binary_path} run --bun build:css"
          warn "=== PostCSS Binary Debug ==="
          warn "Looking for postcss binary:"
          warn `where postcss`  # Windows equivalent of 'which'
          warn "node_modules/.bin:"
          warn `dir node_modules\\.bin\\postcss* 2>&1`
          warn "npm global modules:"
          warn `npm list -g postcss-cli 2>&1`
          warn "==================="
          cmd
        end
      end
    end
  end
end
