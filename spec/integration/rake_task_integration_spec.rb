# frozen_string_literal: true

require 'open3'

RSpec.describe 'rake bun integration', type: :integration do
  let(:gem_root) { File.expand_path('../../', __dir__) }
  let(:tmp_dir) { Dir.mktmpdir('vite_integration_test') }

  before(:each) do
    setup_test_environment
  end

  after(:each) do
    FileUtils.rm_rf(tmp_dir)
  end

  it 'successfully executes the binary through rake task and returns a result' do
    Dir.chdir(tmp_dir) do
      output, status = Open3.capture2e(%{rake "bun[-e 'console.log\\(2+2\\)'"]})
      expect(status).to be_success
      expect(output.strip).to eq('4')
    end
  end

  private

  def setup_test_environment
    File.open(File.join(tmp_dir, 'Rakefile'), 'w') do |f|
      f.puts "require_relative '#{gem_root}/lib/bundlebun'"
    end
  end
end
