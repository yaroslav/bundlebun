# frozen_string_literal: true

require 'fileutils'
require 'json'

namespace :bun do
  desc 'Install bundlebun: install binstub and detect frameworks'
  task 'install' do
    puts <<~MESSAGE
      We are now going to install bundlebun. We'll try to detect the frameworks already in use and install integrations for them.

      Don't forget to run `rake -T bun` to learn more about additional installation tasks for integration with Ruby and JavaScript frameworks, or check the documentation.

      Bun.

    MESSAGE

    Rake::Task['bun:install:bin'].invoke

    if defined?(Cssbundling) || defined?(Jsbundling)
      puts "Rails' cssbundling/jsbundling detected.\n\n"
      Rake::Task['bun:install:bundling-rails'].invoke
    end

    if defined?(ViteRuby)
      puts "vite-ruby detected.\n\n"
      Rake::Task['bun:install:vite'].invoke
    end
  end

  desc 'Install bundlebun: create `bin/bun` binstub'
  task 'install:bin' do
    puts "Installing bin/bun...\n\n"

    source = File.expand_path('../../exe/bundlebun', __dir__)
    target_dir = 'bin'
    target = File.join(target_dir, 'bun')
    content = File.read(source)

    if File.exist?(target)
      puts "#{target} already exists."
    else
      FileUtils.mkdir_p(target_dir)
      File.write(target, content, mode: "w")
      FileUtils.chmod(0o755, target)

      puts "Installed binstub at #{target}."
    end

    # We're using Bundler technique to generate the .cmd wrappers on
    # Windows (as Windows cannot run files with shebangs, of course).
    # There is no public API for generating binstubs (I wish), so that's a copy and paste.
    # @see https://github.com/rubygems/rubygems/blob/186a4f24789e6e7fd967b290ce93ed5886ef22d8/bundler/lib/bundler/installer.rb#L137
    if Gem.win_platform?
      cmd_target = "#{target}.cmd"
      if File.exist?(cmd_target)
        puts "#{cmd_target} already exists."
      else
        prefix = "@ruby -x \"%~f0\" %*\n@exit /b %ERRORLEVEL%\n\n"
        File.write(cmd_target, prefix + content, mode: "wb:UTF-8")
        puts "Installed Windows binstub at #{cmd_target}"
      end
    end

    puts <<~MESSAGE
      Try running it directly. Or, replace existing mentions of `bun` with `bin/bun` in your `package.json`, `Procfile` or binstubs and other files.

      Bun.

    MESSAGE
  end

  desc 'Install bundlebun: cssbundling-rails, jsbundling-rails integration'
  task 'install:bundling-rails' => :install do
    puts "Installing cssbundling/jsbundling Rails integration...\n\n"

    assets_rake = File.expand_path('../templates/bundling-rails/bundlebun.rake', __dir__)
    target_dir = 'lib/tasks'
    target = File.join(target_dir, 'bundlebun.rake')

    if File.exist?(target)
      puts "#{target} already exists."
    else
      FileUtils.mkdir_p(target_dir)
      FileUtils.cp(assets_rake, target)
      puts "Installed an initializer with overrides for cssbundling-rails and jsbundling-rails at #{target}"
    end

    puts <<~MESSAGE
      Install cssbundling-rails [https://github.com/rails/cssbundling-rails] and jsbundling-rails [https://github.com/rails/jsbundling-rails] to get a simple assets pipeline with Rails, powered by Bun.

      Example:

        bundle add cssbundling-rails
        bin/rails css:install:[tailwind|bootstrap|bulma|postcss|sass]
        bin/rails css:build

        bundle add jsbundling-rails
        bin/rails javascript:install:bun

      Those gems enable you to create new Rails templates using Bun, as well as to create a simple build configuration with Bun. Check their READMEs and documentation.

      Be sure to replace `bun` with `bin/bun` in any existing and generated build-related files such as `Procfile` or `Procfile.dev`, `package.json` and others.

      Bun.

    MESSAGE
  end

  desc 'Install bundlebun: vite-ruby integration'
  task 'install:vite' => :install do
    puts "Installing vite-ruby integration...\n\n"

    binstub = File.expand_path('../templates/vite-ruby/bun-vite', __dir__)
    target_dir = 'bin'
    target = File.join(target_dir, 'bun-vite')
    content = File.read(binstub)

    config = File.expand_path('../templates/vite-ruby/vite.json', __dir__)
    config_target_dir = 'config'
    config_target = File.join(config_target_dir, 'vite.json')

    if File.exist?(target)
      puts "#{target} already exists."
    else
      FileUtils.mkdir_p(target_dir)
      File.write(target, content, mode: "w")
      FileUtils.chmod(0o755, target)
      puts "Installed a vite-ruby + bundlebun binstub at #{target}"
    end

    # See above for notes on `.cmd`-file generation.
    if Gem.win_platform?
      cmd_target = "#{target}.cmd"
      if File.exist?(cmd_target)
        puts "#{cmd_target} already exists."
      else
        prefix = "@ruby -x \"%~f0\" %*\n@exit /b %ERRORLEVEL%\n\n"
        File.write(cmd_target, prefix + content, mode: "wb:UTF-8")
        puts "Installed Windows binstub at #{cmd_target}"
      end
    end

    if File.exist?(config_target)
      puts "#{config_target} already exists."

      begin
        json = JSON.parse(File.read(config_target))
        # Injecting our binstub
        json['all'] ||= {}
        json['all']['viteBinPath'] = 'bin/bun-vite'

        File.write(config_target, JSON.pretty_generate(json))
      rescue
        puts "Failed to parse #{config_target}, no changes made."
      end
    else
      FileUtils.mkdir_p(config_target_dir)
      FileUtils.cp(config, config_target)
      puts "Installed sample vite-ruby + bundlebun config at #{config_target}"
    end

    puts <<~MESSAGE
      We've installed a binstub for running vite-ruby with bundlebun enabled at #{target}.
      Use this binstub to force bundlebun with Vite as a JavaScript runtime. Additionally, we've installed (or updated!) a vite-ruby configuration file at #{config_target} to use that binstub.

      Be sure to replace `bun` with `bin/bun` in any existing build-related files such as `Procfile` or `Procfile.dev`, `package.json` and others.

      Bun.

    MESSAGE
  end
end
