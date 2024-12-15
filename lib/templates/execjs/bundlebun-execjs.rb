# An initializer for bundlebun's ExecJS integration.
#
# This introduces ExecJS to the bundlebun'ed version of Bun,
# allows it to run Bun from our binstub, and also sets that
# version of Bun as a default runtime.
#
# Safe to delete if you no longer use bundlebun or
# not interested in running Bun anymore.
Bundlebun::Integrations::ExecJS.bun!
