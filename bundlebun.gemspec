# frozen_string_literal: true

require_relative 'lib/bundlebun/version'

Gem::Specification.new do |spec|
  spec.name = 'bundlebun'

  # This version will be dynamically redefined when building
  # platform-specific gems.
  # Real version: [bundlebun version].[Bun version]
  # Example: 0.1.0.1.1.38
  spec.version = Bundlebun::VERSION

  spec.authors = ['Yaroslav Markin']
  spec.email = ['yaroslav@markin.net']

  spec.summary = 'bundlebun bundles the Bun JavaScript runtime, package manager and build tool, for use with Ruby and Rails'
  spec.description = 'bundlebun bundles Bun, a fast JavaScript runtime, package manager, and builder, with your Ruby and Rails applications. No need to use Docker, devcontainers, `curl | sh`, or `brew`.
'
  spec.homepage = 'https://github.com/yaroslav/bundlebun'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/yaroslav/bundlebun'
  spec.metadata['changelog_uri'] = 'https://github.com/yaroslav/bundlebun/blob/master/CHANGELOG.md'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/yaroslav/bundlebun/issues'
  spec.metadata['documentation_uri'] = 'https://rubydoc.info/gems/bundlebun'
  spec.metadata['rbs_source'] = 'sig'
  spec.post_install_message = 'Bun.'

  spec.files = Dir['lib/**/*', 'sig/**/*', 'exe/*', 'LICENSE.txt', 'README.md', 'CHANGELOG.md']
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.extra_rdoc_files = ['README.md']
  spec.require_paths = ['lib']
  spec.add_runtime_dependency 'zeitwerk'
  spec.add_runtime_dependency 'json'
end
