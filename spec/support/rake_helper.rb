# frozen_string_literal: true

module RakeHelper
  def load_rake_tasks
    rake = Rake::Application.new
    Rake.application = rake
    load File.expand_path('../../lib/tasks/bun.rake', __dir__)
    yield rake if block_given?
  end
end
