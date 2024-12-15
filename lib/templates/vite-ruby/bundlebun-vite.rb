# An initializer vite-ruby integration.
# We need both this initializer and a custom binstub at `bin/vite`.
#
# This forces vite-ruby to run bundlebun'ed version of Bun as a
# JavaScript runtime.
#
# Safe to delete if you no longer use bundlebun or
# not interested in running Bun anymore.
Bundlebun::Integrations::ViteRuby.bun!
