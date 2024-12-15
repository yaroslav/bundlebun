# frozen_string_literal: true

module Bundlebun
  module Integrations
    # An integration for execjs[https://github.com/rails/execjs].
    #
    # Runtimes in ExecJS are declared like this: https://github.com/rails/execjs/blob/master/lib/execjs/runtimes.rb
    # We will redefine the Bun one, changing its command.
    #
    # Then, we will automatically set the bundlebun-ed Bun as the default runtime.
    module ExecJS
      # Patches the existing module to use bundlebun-ed Bun in place of an
      # already existing, spported Bun runtime: we replace it with a bundled version.
      #
      # Additionally, sets it asa default ExecJS runtime.
      #
      # Call this after everything is loaded and required.
      # For a Rails application, a good place is an initializer.
      #
      # See the documentation for more info on installation Rake tasks.
      def self.bun!
        return unless defined?(::ExecJS::Runtimes)

        # Remove the existing Bun constant if it exists
        ::ExecJS::Runtimes.send(:remove_const, :Bun) if ::ExecJS::Runtimes.const_defined?(:Bun)

        # Define new Bun runtime with our custom command
        bun_runtime = ::ExecJS::Runtimes.const_set(:Bun,
          ::ExecJS::ExternalRuntime.new(
            name: "Bun.sh",
            command: [Bundlebun::Runner.binstub_or_binary_path],
            runner_path: ::ExecJS.root + "/support/bun_runner.js",
            encoding: "UTF-8"
          ))

        # Set the runtime
        ::ExecJS.runtime = bun_runtime
      end
    end
  end
end
