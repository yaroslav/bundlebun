# frozen_string_literal: true

require 'rake'

RSpec.describe 'rake bun:install' do
  let(:rake) { Rake::Application.new }
  let(:lib_tasks_dir) { 'lib/tasks' }

  before do
    Rake.application = rake
    load 'tasks/install.rake'

    allow(FileUtils).to receive(:mkdir_p).and_return(true)
    allow(FileUtils).to receive(:cp).and_return(true)
    allow(FileUtils).to receive(:chmod).and_return(true)
    allow(FileUtils).to receive(:mv).and_return(true)

    allow(File).to receive(:exist?).and_return(false)
    allow(File).to receive(:expand_path).and_return('/source/path')
    allow(File).to receive(:read).with('/source/path').and_return("#!/usr/bin/env ruby\nputs 'hello'")
    allow(File).to receive(:write)

    allow($stdout).to receive(:puts)
  end

  after do
    Rake.application.clear
    Rake::Task.clear
  end

  describe 'bun:install' do
    before do
      allow(File).to receive(:exist?).with('bin/bun').and_return(true)
    end

    it 'invokes the bin installation task' do
      expect(Rake::Task['bun:install:bin']).to receive(:invoke)
      Rake::Task['bun:install'].invoke
    end

    context 'with Cssbundling/Jsbundling defined' do
      before do
        stub_const('Cssbundling', Class.new)
      end

      it 'invokes the bundling-rails installation task' do
        expect(Rake::Task['bun:install:bundling-rails']).to receive(:invoke)
        Rake::Task['bun:install'].invoke
      end
    end

    context 'with ViteRuby defined' do
      before do
        stub_const('ViteRuby', Class.new)
      end

      it 'invokes the Vite installation task' do
        expect(Rake::Task['bun:install:vite']).to receive(:invoke)
        Rake::Task['bun:install'].invoke
      end
    end
  end

  describe 'bun:install:bin' do
    let(:binstub) { 'bin/bun' }
    let(:cmd_binstub) { 'bin/bun.cmd' }
    let(:source_content) { "#!/usr/bin/env ruby\nputs 'hello'" }

    before do
      allow(File).to receive(:exist?).with(binstub).and_return(false)
      allow(File).to receive(:exist?).with(cmd_binstub).and_return(false)
      allow(File).to receive(:write).and_return(true)
      allow(Gem).to receive(:win_platform?).and_return(true)
    end

    context 'when binstub does not exist' do
      before do
        allow(File).to receive(:exist?).with(binstub).and_return(false)
      end

      it 'creates the Unix binstub' do
        expect(FileUtils).to receive(:mkdir_p).with('bin')
        expect(File).to receive(:write).with(binstub, source_content, mode: "w")
        expect(FileUtils).to receive(:chmod).with(0o755, binstub)
        Rake::Task['bun:install:bin'].invoke
      end
    end

    context 'when binstub exists' do
      before do
        allow(File).to receive(:exist?).with(binstub).and_return(true)
      end

      it 'skips the Unix binstub' do
        expect(File).not_to receive(:write).with(binstub, anything, anything)
        Rake::Task['bun:install:bin'].invoke
      end
    end

    context 'when Windows binstub does not exist' do
      before do
        allow(File).to receive(:exist?).with(cmd_binstub).and_return(false)
      end

      it 'creates the Windows binstub' do
        expect(File).to receive(:write).with(
          cmd_binstub,
          "@ruby -x \"%~f0\" %*\n@exit /b %ERRORLEVEL%\n\n" + source_content,
          mode: "wb:UTF-8"
        )
        Rake::Task['bun:install:bin'].invoke
      end
    end

    context 'when Windows binstub exists' do
      before do
        allow(File).to receive(:exist?).with(cmd_binstub).and_return(true)
      end

      it 'skips the Windows binstub' do
        expect(File).not_to receive(:write).with(cmd_binstub, anything, anything)
        Rake::Task['bun:install:bin'].invoke
      end
    end
  end

  describe 'bun:install:bundling-rails' do
    let(:lib_tasks_dir) { 'lib/tasks' }
    let(:assets_rake_file) { File.join(lib_tasks_dir, 'bundlebun.rake') }
    let(:template_dir) { File.expand_path('../templates', __dir__) }
    let(:rails_template_dir) { File.join(template_dir, 'rails') }

    before do
      allow(File).to receive(:exist?).with('bin/bun').and_return(true)
      allow(File).to receive(:expand_path).with('../templates/bundling-rails/bundlebun.rake', anything)
        .and_return(File.join(rails_template_dir, 'bundlebun.rake'))
    end

    context 'when performing fresh installation' do
      before do
        allow(File).to receive(:exist?).with(assets_rake_file).and_return(false)
        allow(FileUtils).to receive(:mkdir_p).with(lib_tasks_dir).and_return(true)
        allow(FileUtils).to receive(:cp).and_return(true)
      end

      it 'creates a rake task from template' do
        expect(FileUtils).to receive(:mkdir_p).with(lib_tasks_dir)
        expect(FileUtils).to receive(:cp).with(
          File.join(rails_template_dir, 'bundlebun.rake'),
          assets_rake_file
        )

        Rake::Task['bun:install:bundling-rails'].invoke
      end
    end

    context 'when a rake task file already exists' do
      before do
        allow(File).to receive(:exist?).with(assets_rake_file).and_return(true)
        allow(FileUtils).to receive(:mkdir_p).with(lib_tasks_dir).and_return(true)
        allow(FileUtils).to receive(:cp).and_return(false)
      end

      it 'skips creation of the rake task file' do
        expect(FileUtils).not_to receive(:cp)

        Rake::Task['bun:install:bundling-rails'].invoke
      end
    end
  end

  describe 'bun:install:vite' do
    let(:bin_dir) { 'bin' }
    let(:config_dir) { 'config' }
    let(:vite_binstub) { 'bin/bun-vite' }
    let(:vite_cmd_binstub) { 'bin/bun-vite.cmd' }
    let(:vite_config) { 'config/vite.json' }
    let(:source_content) { "#!/usr/bin/env ruby\nputs 'hello'" }

    before do
      allow(File).to receive(:exist?).with('bin/bun').and_return(true)

      allow(Gem).to receive(:win_platform?).and_return(false)

      allow(File).to receive(:expand_path).with('../templates/vite-ruby/bun-vite', anything)
        .and_return('/source/path')
      allow(File).to receive(:expand_path).with('../templates/vite-ruby/vite.json', anything)
        .and_return('/source/path/vite.json')

      allow(File).to receive(:read).with('/source/path').and_return(source_content)

      allow(FileUtils).to receive(:chmod)
      allow(FileUtils).to receive(:cp)
    end

    context 'when no files exist' do
      before do
        allow(File).to receive(:exist?).with(vite_binstub).and_return(false)
        allow(File).to receive(:exist?).with(vite_config).and_return(false)
      end

      it 'creates the binstub' do
        expect(FileUtils).to receive(:mkdir_p).with(bin_dir)
        expect(File).to receive(:write).with(vite_binstub, source_content, mode: "w")
        expect(FileUtils).to receive(:chmod).with(0o755, vite_binstub)
        Rake::Task['bun:install:vite'].invoke
      end

      it 'creates the config file' do
        expect(FileUtils).to receive(:mkdir_p).with(config_dir)
        expect(FileUtils).to receive(:cp).with('/source/path/vite.json', vite_config)
        Rake::Task['bun:install:vite'].invoke
      end

      context 'on Windows' do
        before do
          allow(Gem).to receive(:win_platform?).and_return(true)
          allow(File).to receive(:exist?).with(vite_cmd_binstub).and_return(false)
        end

        it 'creates the windows binstub' do
          expect(FileUtils).to receive(:mkdir_p).with(bin_dir)
          expect(File).to receive(:write).with(
            vite_cmd_binstub,
            "@ruby -x \"%~f0\" %*\n@exit /b %ERRORLEVEL%\n\n#{source_content}",
            mode: "wb:UTF-8"
          )
          Rake::Task['bun:install:vite'].invoke
        end
      end
    end

    context 'when binstub exists' do
      before do
        allow(File).to receive(:exist?).with(vite_binstub).and_return(true)
        allow(File).to receive(:exist?).with(vite_config).and_return(false)
      end

      it 'skips binstub creation' do
        expect(File).not_to receive(:write).with(vite_binstub, anything, anything)
        Rake::Task['bun:install:vite'].invoke
      end

      context 'on Windows' do
        before do
          allow(Gem).to receive(:win_platform?).and_return(true)
          allow(File).to receive(:exist?).with(vite_cmd_binstub).and_return(false)
        end

        it 'still creates the windows binstub' do
          expect(File).to receive(:write).with(
            vite_cmd_binstub,
            "@ruby -x \"%~f0\" %*\n@exit /b %ERRORLEVEL%\n\n#{source_content}",
            mode: "wb:UTF-8"
          )
          Rake::Task['bun:install:vite'].invoke
        end
      end
    end

    context 'when windows binstub exists' do
      before do
        allow(Gem).to receive(:win_platform?).and_return(true)
        allow(File).to receive(:exist?).with(vite_binstub).and_return(false)
        allow(File).to receive(:exist?).with(vite_cmd_binstub).and_return(true)
        allow(File).to receive(:exist?).with(vite_config).and_return(false)
      end

      it 'skips windows binstub creation' do
        expect(File).not_to receive(:write).with(vite_cmd_binstub, anything, anything)
        Rake::Task['bun:install:vite'].invoke
      end
    end

    context 'when config exists' do
      let(:existing_config) { {'all' => {'existingKey' => 'value'}} }

      before do
        allow(File).to receive(:exist?).with(vite_binstub).and_return(true)
        allow(File).to receive(:exist?).with(vite_config).and_return(true)
        allow(File).to receive(:read).with(vite_config).and_return(JSON.generate(existing_config))
      end

      it 'updates existing config with viteBinPath' do
        expected_config = {
          'all' => {
            'existingKey' => 'value',
            'viteBinPath' => 'bin/bun-vite'
          }
        }
        expect(File).to receive(:write).with(
          vite_config,
          JSON.pretty_generate(expected_config)
        )
        Rake::Task['bun:install:vite'].invoke
      end
    end

    context 'when config exists but is invalid JSON' do
      before do
        allow(File).to receive(:exist?).with(vite_binstub).and_return(true)
        allow(File).to receive(:exist?).with(vite_config).and_return(true)
        allow(File).to receive(:read).with(vite_config).and_return('invalid json')
      end

      it 'handles the error gracefully' do
        expect(File).not_to receive(:write).with(vite_config, anything)
        expect { Rake::Task['bun:install:vite'].invoke }.not_to raise_error
      end

      it 'outputs an error message' do
        expect($stdout).to receive(:puts).with(/Failed to parse .+vite\.json, no changes made\./)
        Rake::Task['bun:install:vite'].invoke
      end
    end

    context 'task dependencies' do
      it 'depends on bun:install' do
        expect(Rake::Task['bun:install:vite'].prerequisites).to include('install')
      end
    end
  end
end
