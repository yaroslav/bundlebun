# frozen_string_literal: true

require 'rake'

# Rake command/parameter handling is limited, so we
# need to use the <tt>[]</tt>-syntax.
#
# Even when using <tt>--</tt> with something like
# <tt>rake bun -- -e 'console.log(1)'</tt>, Rack thinks that
# <tt>console.log...</tt> is a task it needs to run, warns about an
# error (although still executes known tasks).
#
# Example:
#
#   rake "bun[-e 'console.log(2+2)']"
#
desc 'Run bundled Bun with parameters. Example: rake "bun[build]"'
task :bun, [:command] do |_t, args|
  command = args[:command] || ''
  Bundlebun::Runner.call(command)
end
