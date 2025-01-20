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
    before do
      allow(File).to receive(:exist?).with('bin/bun').and_return(false)
    end

    it 'creates the binstub file' do
      expect(FileUtils).to receive(:mkdir_p).with('bin')
      expect(FileUtils).to receive(:cp)
      expect(FileUtils).to receive(:chmod).with(0o755, 'bin/bun')

      Rake::Task['bun:install:bin'].invoke
    end

    context 'when binstub already exists' do
      before do
        allow(File).to receive(:exist?).with('bin/bun').and_return(true)
      end

      it 'skips creation of binstub' do
        expect(FileUtils).not_to receive(:cp)
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
    let(:initializers_dir) { 'config/initializers' }
    let(:bin_dir) { 'bin' }
    let(:vite_binstub) { 'bin/vite' }
    let(:vite_backup) { 'bin/vite-backup' }
    let(:vite_initializer) { 'config/initializers/bundlebun-vite.rb' }
    let(:template_dir) { File.expand_path('../templates', __dir__) }
    let(:vite_template_dir) { File.join(template_dir, 'vite-ruby') }

    before do
      allow(File).to receive(:exist?).with('bin/bun').and_return(true)
      allow(File).to receive(:directory?).with(initializers_dir).and_return(true)

      allow(File).to receive(:expand_path).with('../templates/vite-ruby/vite', anything)
        .and_return(File.join(vite_template_dir, 'vite'))
      allow(File).to receive(:expand_path).with('../templates/vite-ruby/bundlebun-vite.rb', anything)
        .and_return(File.join(vite_template_dir, 'bundlebun-vite.rb'))
    end

    context 'when performing fresh installation' do
      before do
        allow(File).to receive(:exist?).with(vite_binstub).and_return(false)
        allow(File).to receive(:exist?).with(vite_initializer).and_return(false)
      end

      it 'creates both binstub and initializer' do
        expect(FileUtils).to receive(:mkdir_p).with(bin_dir)
        expect(FileUtils).to receive(:cp).with(
          File.join(vite_template_dir, 'vite'),
          vite_binstub
        )
        expect(FileUtils).to receive(:cp).with(
          File.join(vite_template_dir, 'bundlebun-vite.rb'),
          vite_initializer
        )
        expect(FileUtils).to receive(:chmod).with(0o755, vite_binstub)

        Rake::Task['bun:install:vite'].invoke
      end
    end

    context 'when vite binstub exists without bundlebun mentioned in it' do
      before do
        allow(File).to receive(:exist?).with(vite_binstub).and_return(true)
        allow(File).to receive(:read).with(vite_binstub).and_return('regular vite content')
        allow(File).to receive(:exist?).with(vite_initializer).and_return(false)
      end

      it 'backs up existing binstub and creates new one' do
        expect(FileUtils).to receive(:mv).with(vite_binstub, vite_backup)
        expect(FileUtils).to receive(:cp).with(
          File.join(vite_template_dir, 'vite'),
          vite_binstub
        )
        expect(FileUtils).to receive(:chmod).with(0o755, vite_binstub)
        expect(FileUtils).to receive(:cp).with(
          File.join(vite_template_dir, 'bundlebun-vite.rb'),
          vite_initializer
        )

        Rake::Task['bun:install:vite'].invoke
      end
    end

    context 'when vite binstub exists with bundlebun mentioned in it' do
      before do
        allow(File).to receive(:exist?).with(vite_binstub).and_return(true)
        allow(File).to receive(:read).with(vite_binstub).and_return('content with bundlebun')
        allow(File).to receive(:exist?).with(vite_initializer).and_return(false)
      end

      it 'skips binstub creation but creates initializer' do
        expect(FileUtils).not_to receive(:mv)
        expect(FileUtils).not_to receive(:chmod)
        expect(FileUtils).not_to receive(:cp).with(anything, vite_binstub)

        expect(FileUtils).to receive(:cp).with(
          File.join(vite_template_dir, 'bundlebun-vite.rb'),
          vite_initializer
        )

        Rake::Task['bun:install:vite'].invoke
      end
    end

    context 'when initializers directory does not exist' do
      before do
        allow(File).to receive(:directory?).with(initializers_dir).and_return(false)
        allow(File).to receive(:exist?).with(vite_binstub).and_return(false)
      end

      it 'creates binstub but skips initializer' do
        expect(FileUtils).to receive(:mkdir_p).with(bin_dir)
        expect(FileUtils).to receive(:cp).with(
          File.join(vite_template_dir, 'vite'),
          vite_binstub
        )
        expect(FileUtils).to receive(:chmod).with(0o755, vite_binstub)

        expect(FileUtils).not_to receive(:cp).with(anything, vite_initializer)

        Rake::Task['bun:install:vite'].invoke
      end
    end
  end
end
