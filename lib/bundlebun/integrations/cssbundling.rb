# frozen_string_literal: true

module Bundlebun
  module Integrations
    # A Bundlebun integration for cssbundling-rails[https://github.com/rails/cssbundling-rails].
    #
    # It's hard to override those methods on the fly, and a Rails initializer in the
    # target project also does not seem to work, so we have to create a dummy task
    # in the actual Rails project, and patch the helper module Tasks from there.
    #
    # When installed, makes it run a bundled Bun runtime for packing tasks.
    #
    # See: https://github.com/rails/cssbundling-rails/blob/main/lib/tasks/cssbundling/build.rake
    module Cssbundling
      # Patches the existing module.
      #
      # Call this after everything is loaded and required.
      # For a Rails application, a good place is... not an initializer,
      # but some code that can be run in a Rake task. Like a custom Rake task
      # in <tt>lib/tasks</tt>.
      #
      # See the documentation for more info on installation Rake tasks.
      def self.bun!
        return unless defined?(::Cssbundling::Tasks)

        ::Cssbundling::Tasks.prepend(self::Tasks)
      end

      module Tasks # :nodoc:
        extend self

        def install_command
          "#{Bundlebun::Runner.binstub_or_binary_path} install"
        end

        def build_command
          "#{Bundlebun::Runner.binstub_or_binary_path} run --bun build:css"
        end
      end
    end
  end
end
