module Bundlebun
  # Bundlebun includes several integrations for frontend-related gems and frameworks.
  #
  # Usuall, you would need to run a provided Rake task (see the list at <tt>rake -T bun</tt>)
  # to install any initializers or binstubs you might need.
  # Then, the provided files will help you to initialise (patch) the code.
  #
  # Typically, to call an integration / patch the loaded code, you would need to call
  # the <tt>bun!</tt> method, like:
  #
  #   Bundlebun::Integrations::Foobar.bun!
  #
  # See the documentation to learn about the supported integrations.
  module Integrations
  end
end
