# frozen_string_literal: true

require 'fileutils'

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

    if File.exist?(target)
      puts "#{target} already exists."
    else
      FileUtils.mkdir_p(target_dir)
      FileUtils.cp(source, target)
      FileUtils.chmod(0o755, target)

      puts "Installed binstub at #{target}."
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

    binstub = File.expand_path('../templates/vite-ruby/vite', __dir__)
    target_dir = 'bin'
    initializers_dir = 'config/initializers'
    target = File.join(target_dir, 'vite')
    backup = File.join(target_dir, 'vite-backup')
    initializer = File.expand_path('../templates/vite-ruby/bundlebun-vite.rb', __dir__)
    initializer_target = File.join(initializers_dir, 'bundlebun-vite.rb')

    if File.exist?(target) && File.read(target).include?('bundlebun')
      puts "#{target} already exists."
    elsif File.exist?(target)
      puts "Copying #{target} to #{backup} for backup"
      FileUtils.mv(target, backup)

      FileUtils.cp(binstub, target)
      FileUtils.chmod(0o755, target)
      puts "Installed a vite-ruby + bundlebun binstub at #{target}"
    else
      FileUtils.mkdir_p(target_dir)
      FileUtils.cp(binstub, target)
      FileUtils.chmod(0o755, target)
      puts "Installed a vite-ruby + bundlebun binstub at #{target}"
    end

    if File.directory?(initializers_dir)
      if File.exist?(initializer_target)
        puts "#{initializer_target} already exists."
      else
        FileUtils.cp(initializer, initializer_target)
        puts "Installed a Rails initializer for vite-ruby at #{initializer_target}."
      end
    else
      puts "Directory #{initializers_dir} does not seem to exist; not installing a Rails initializer."
    end

    puts <<~MESSAGE
      We've installed a binstub for running vite-ruby with bundlebun enabled at #{target}.
      vite-ruby should now use this patched binstub to use `bin/bun` with bundlebun as a JavaScript runtime. Additionally, we've tried to install a Rails initializer at
      #{initializer_target} to help vite-ruby work with bundlebun.

      Be sure to replace `bun` with `bin/bun` in any existing and generated build-related files such as `Procfile` or `Procfile.dev`, `package.json` and others.

      Bun.

    MESSAGE
  end

  desc 'Install bundlebun: ExecJS integration'
  task 'install:execjs' => :install do
    puts "Installing ExecJS integration...\n\n"

    initializers_dir = 'config/initializers'
    initializer = File.expand_path('../templates/execjs/bundlebun-execjs.rb', __dir__)
    initializer_target = File.join(initializers_dir, 'bundlebun-execjs.rb')

    if File.directory?(initializers_dir)
      if File.exist?(initializer_target)
        puts "#{initializer_target} already exists."
      else
        FileUtils.cp(initializer, initializer_target)
        puts "Installed a Rails initializer for ExecJS at #{initializer_target}."
      end
    else
      puts "Directory #{initializers_dir} does not seem to exist; not installing a Rails initializer."
    end

    puts <<~MESSAGE
      We've installed a Rails initializer that re-defines the Bun runtime for ExecJS and
      sets Bun as a default runtime.

      Bun.

    MESSAGE
  end
end
