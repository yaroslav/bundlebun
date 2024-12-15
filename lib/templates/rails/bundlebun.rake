# An initializer of sorts for bundlebun's ExecJS integration.
# Can't go to `initializers`, does not trigger that way.
#
# This forces cssbundling and jsbundling to use a bundlebun'ed
# version of Bun for building assets.
#
# Safe to delete if you no longer use bundlebun or
# not interested in running Bun anymore.
Bundlebun::Integrations::Cssbundling.bun!
Bundlebun::Integrations::Jsbundling.bun!
