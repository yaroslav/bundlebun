# frozen_string_literal: true

module Bundlebun
  # bundlebun uses the `#{bundlebun.version}.#{bun.version}`
  # versioning scheme.
  # gem bundlebun version `0.1.0.1.1.38` is a distribution
  # that includes a gem with its own code version `0.1.0` and
  # a Bun runtime with version `1.1.38`.
  #
  # This constant always points to the "own" version of the gem.
  VERSION = '0.4.0'
end
