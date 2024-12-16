# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'yard'

RSpec::Core::RakeTask.new(:spec)

YARD::Rake::YardocTask.new do |t|
  t.files = ['lib/**/*.rb']
  t.options = ['--any-option']
  t.stats_options = ['--list-undoc']
end

require 'standard/rake'

Dir.glob('tasks/*.{rb,rake}').each { |file| load file }

task default: %i[spec]
