# frozen_string_literal: true

require 'open3'

RSpec.describe 'rake bun integration', type: :integration do
  let(:gem_root) { File.expand_path('../../', __dir__) }
  let(:tmp_dir) { Dir.mktmpdir('bun_integration_test') }

  before(:each) do
    setup_test_environment
  end

  after(:each) do
    FileUtils.rm_rf(tmp_dir)
  end

  it 'successfully executes the binary through rake task and returns a result' do
    Dir.chdir(tmp_dir) do
      command = if Bundlebun::Platform.windows?
        'rake "bun[-e \"console.log(2+2)\"]"'
      else
        %{rake "bun[-e 'console.log\\(2+2\\)']"}
      end

      output, status = Open3.capture2e(command)
      expect(status).to be_success
      expect(output.strip).to eq('4')
    end
  end

  describe 'bun:install:package' do
    it 'migrates package.json scripts to use bin/bun' do
      Dir.chdir(tmp_dir) do
        File.write('package.json', <<~JSON)
          {
            "name": "test-app",
            "scripts": {
              "build": "bun build ./src/index.ts",
              "dev": "bunx vite",
              "lint": "npx eslint .",
              "test": "npm run build && bun test"
            }
          }
        JSON

        _, status = Open3.capture2e('rake bun:install:package', stdin_data: "\n")
        expect(status).to be_success

        result = JSON.parse(File.read('package.json'))
        expect(result['scripts']['build']).to eq('bin/bun build ./src/index.ts')
        expect(result['scripts']['dev']).to eq('bin/bun x vite')
        expect(result['scripts']['lint']).to eq('bin/bun x eslint .')
        expect(result['scripts']['test']).to eq('bin/bun run build && bin/bun test')
      end
    end

    it 'preserves scripts already using bin/bun' do
      Dir.chdir(tmp_dir) do
        File.write('package.json', <<~JSON)
          {
            "name": "test-app",
            "scripts": {
              "build": "bin/bun build ./src/index.ts"
            }
          }
        JSON

        output, status = Open3.capture2e('rake bun:install:package')
        expect(status).to be_success
        expect(output).to include('already use bin/bun')

        result = JSON.parse(File.read('package.json'))
        expect(result['scripts']['build']).to eq('bin/bun build ./src/index.ts')
      end
    end
  end

  private

  def setup_test_environment
    File.open(File.join(tmp_dir, 'Rakefile'), 'w') do |f|
      f.puts "require_relative '#{gem_root}/lib/bundlebun'"
    end
  end
end
