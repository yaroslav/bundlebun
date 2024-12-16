module Bundlebun
  # Bundlebun includes several integrations for frontend-related gems and frameworks.
  #
  # Usually you would need to run a provided Rake task (see the list at `rake -T bun`)
  # to install any initializers or binstubs you might need.
  # Then, the provided files will help you to initialize (patch) the code.
  #
  # Typically, to call an integration / patch the loaded code, you would need to call
  # the `bun!` method, like `Bundlebun::Integrations::Foobar.bun!`.
  #
  # See the documentation to learn about the supported integrations.
  module Integrations
  end
end
