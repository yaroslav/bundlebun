# frozen_string_literal: true

module Bundlebun
  module Integrations
    # An integration for vite-ruby[https://github.com/ElMassimo/vite_ruby] and vite-rails[https://vite-ruby.netlify.app/].
    #
    # For that, we would need both to replace the vite binstub (as <tt>bin/vite</tt>
    # exists by itself and does not really initialize this gem if it is installed),
    # and redefine the RunnerExtensions for ViteRuby by calling this patch from
    # a Rails initializer.
    # This way, a typical <tt>bin/dev</tt> would work, as well as integration tests.
    module ViteRuby
      # Patches the existing module.
      #
      # Call this after everything is loaded and required.
      # For a Rails application, a good place is an initializer.
      #
      # See the documentation for more info on installation Rake tasks.
      def self.bun!
        return unless defined?(::ViteRuby::Runner)

        ::ViteRuby::Runner.prepend(self::RunnerExtensions)
      end

      module RunnerExtensions # :nodoc:
        # Internal: Resolves to an executable for Vite.
        #
        # We're overloading this to use with bundlebun.
        def vite_executable(*exec_args)
          # Should still allow a custom bin path/binstub
          bin_path = config.vite_bin_path
          return [bin_path] if bin_path && File.exist?(bin_path)

          # Would be cleaner is to check `if config.package_manager == 'bun'`,
          # but seems redundant since we're already bundling Bun,
          # and putting `bun` as a package manager in their vite.json is just
          # another step for the developer to do.
          [bun_binstub_path, 'x --bun', *exec_args, 'vite']
        end

        # Use our binstub if it is installed in the project,
        # otherwise just use the binary included with the gem.
        def bun_binstub_path
          Bundlebun::Runner.binstub_or_binary_path
        end
      end
    end
  end
end
