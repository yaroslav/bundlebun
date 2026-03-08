# bundlebun

**bundlebun** bundles [Bun](https://bun.sh)—the all-in-one JavaScript runtime, package manager, and build tool—directly into your Ruby gem bundle. No Docker, no `curl | sh`, no Homebrew required.

<div align="center">
  <img src="https://raw.githubusercontent.com/yaroslav/bundlebun/refs/heads/main/assets/mr-bundlebun-512.png" width="256" height="256" alt="Mr. Bundlebun" title="Mr. Bundlebun">
</div>

* **Zero setup.** `bundle add bundlebun && rake bun:install` and you're done.
* **Team-friendly.** Everyone runs the same Bun version, pinned in `Gemfile.lock`.
* **Auto-updating.** New Bun release? bundlebun ships it automatically. Or freeze your preferred version.
* **Integrates automatically.** Works out of the box with vite-ruby, cssbundling-rails, jsbundling-rails, and ExecJS.

```sh
bundle add bundlebun
rake bun:install
bin/bun --version
```

[![GitHub Release](https://img.shields.io/github/v/release/yaroslav/bundlebun)](https://github.com/yaroslav/bundlebun/releases)
[![Docs](https://img.shields.io/badge/yard-docs-blue.svg)](https://rubydoc.info/gems/bundlebun)

---

## Table of Contents

- [Rationale](#rationale)
- [Install](#install)
- [Usage](#usage)
- [Integrations](#integrations)
- [Versioning](#versioning)
- [Uninstall](#uninstall)
- [Acknowledgements](#acknowledgements)
- [Contributing](#contributing)
- [License](#license)

## Rationale

**Modern frontend setup is needlessly complex** and may involve a lot of maintenance. Developers need _at the very least_ a JavaScript runtime (typically, Node.js), a package manager (could be npm, yarn, or pnpm), and a build tool (Vite, Webpack, esbuild, Parcel—dozens of them).

- One way forward is to dockerize development environments, creating unnecessary headaches for the development team—both frontend and backend engineers (especially if the team is not that large and the project is not that complex).
- Another approach is to declare front-ops bankruptcy and pursue the "no-build" route.

**What if we could simplify this?** **Bun** is a **JavaScript runtime**, optimized for speed and developer experience. Bun is _also_ a fast JavaScript **package manager**. Bun is _also_ a **build tool**. Bun is also distributed as a single executable file.

However, Bun still requires [some installation](https://bun.sh/docs/installation), and we need to make sure everyone on the team is using the same version.

So, how about we just pack it into a Ruby gem as a binary and allow developers to stay updated? Then, we'll be ready every time a new Bun version is out—or the user can freeze their desired version within their Ruby project. There are no setups, large READMEs with instructions, and no enforcing the Docker workflow.

**Enter bundlebun**. With a fast JavaScript runtime and a package manager included, you can even skip the build tool and use Bun itself.

## Install

bundlebun gem releases include a binary distribution of Bun for each supported Bun platform (macOS, Linux, Windows) and architecture. bundlebun is tested for Unix-like environments and Windows.

Add bundlebun to your `Gemfile`, placing it _after_ your existing frontend-related gems:

```ruby
# Frontend-related gems go here
# gem "vite_rails"

gem "bundlebun"
```

Then run:

```sh
bundle add bundlebun
rake bun:install
```

`rake bun:install` creates a `bin/bun` binstub and auto-detects which integrations to enable. It will also offer to migrate `package.json` scripts and `Procfile` entries to use `bin/bun`.

_If you're seeing a message like `Could not find gems matching 'bundlebun' valid for all resolution platforms (aarch64-linux, aarch64-linux-gnu <...> )`, [check this article](https://github.com/yaroslav/bundlebun/wiki/Could-not-find-gems-matching-'bundlebun'-valid-for-all-resolution-platforms)._

_Windows:_ `bin\bun.cmd` is created instead. If you joined a project with only the Unix binstub, run `rake bun:install` again.

## Usage

### Binstub

The easiest way to run Bun is via the `bin/bun` binstub:

```sh
bin/bun install
bin/bun add postcss
bin/bun run build
```

### PATH

bundlebun prepends the bundled Bun directory to your application's `PATH`. Tools that detect a `bun` executable (like vite-ruby) find it automatically—no extra configuration needed.

### Rake

Alternatively, you can use a Rake task. The syntax is far from perfect—that's a limitation of Rake—but it's an option if you cannot install the binstub. Note the quotes around the parameters:

```sh
rake bun[command]  # Run bundled Bun with parameters
```

```sh
> rake "bun[outdated]"
bun outdated v1.1.38 (bf2f153f)
...
```

### Ruby API

```ruby
Bundlebun.('install')               # exec: replaces the current Ruby process with Bun
Bundlebun.call(['add', 'postcss'])  # same thing, array form
```

**Note:** `Bundlebun.call` (and the `()` shortcut) replaces the current process—it never returns. Use `Bundlebun.system` to run Bun and continue executing Ruby:

```ruby
if Bundlebun.system('install')
  puts 'Dependencies installed!'
end

success = Bundlebun.system('test')
# => true if Bun exited successfully, false or nil otherwise
```

See the [API documentation](https://rubydoc.info/gems/bundlebun) for full details on `Bundlebun::Runner`.

### Instrumentation

When ActiveSupport is available, bundlebun emits events you can subscribe to:

```ruby
ActiveSupport::Notifications.subscribe('system.bundlebun') do |event|
  Rails.logger.info "Bun: #{event.payload[:command]} (#{event.duration.round(1)}ms)"
end
```

Events: `system.bundlebun` (for `Bundlebun.system`) and `exec.bundlebun` (for `Bundlebun.call`). Payload: `{ command: args }`.

## Integrations

bundlebun auto-detects and loads integrations when you run `rake bun:install`—as long as `gem "bundlebun"` is placed _after_ the relevant gems in your `Gemfile`.

### vite-ruby / vite-rails

[vite-ruby](https://github.com/ElMassimo/vite_ruby) and [vite-rails](https://vite-ruby.netlify.app/) are gems that make Ruby and Rails integration with [Vite](https://vite.dev/), a great JavaScript build tool and platform, seamless and easy.

The bundlebun integration is installed automatically with `rake bun:install`, or you can run it explicitly:

```sh
rake bun:install:vite
```

That will make sure you have a `bin/bun` binstub. Next, it installs a custom `bin/bun-vite` binstub to use in build scripts, and creates or updates `vite.json` to use that binstub for building. See the [Vite Ruby configuration manual](https://vite-ruby.netlify.app/config/index.html) for details on `vite.json`.

To enable the integration manually:

```ruby
Bundlebun::Integrations::ViteRuby.bun!
```

### cssbundling-rails / jsbundling-rails

[cssbundling-rails](https://github.com/rails/cssbundling-rails) and [jsbundling-rails](https://github.com/rails/jsbundling-rails) are Rails gems that support the traditional CSS and JS building pipeline for Ruby on Rails.

Be sure to check both gems for documentation on bootstrapping your frontend build pipeline instead of duplicating approaches here. cssbundling-rails, for instance, includes an excellent sample build configuration for Bun.

```sh
# Bootstrap cssbundling-rails
bundle add cssbundling-rails
bin/rails css:install:[tailwind|bootstrap|bulma|postcss|sass]

# Bootstrap jsbundling-rails
bundle add jsbundling-rails
bin/rails javascript:install:bun

# Ensure bundlebun integration
rake bun:install:bundling-rails
```

### ExecJS

[ExecJS](https://github.com/rails/execjs) runs JavaScript code straight from Ruby. It supports a number of runtimes it can launch—and get a result from. Bun runtime support already exists in ExecJS; bundlebun just ensures it uses the bundled version.

Works automatically when bundlebun loads after ExecJS in your `Gemfile`. To enable manually:

```ruby
Bundlebun::Integrations::ExecJS.bun!
```

## Versioning

bundlebun versions follow the `#{gem.version}.#{bun.version}` scheme. For example, `0.1.0.1.1.38` = gem version `0.1.0` + Bun `1.1.38`.

New gem versions are published automatically on each Bun release. Lock to a specific Bun version in your `Gemfile`, or leave it unspecified to always get the latest.

## Uninstall

```sh
bundle remove bundlebun
```

Then clean up:

- `bin/bun` (and `bin\bun.cmd` on Windows)
- `bin/bun-vite` if present
- `tasks/bundlebun.rake` if present
- Any `bin/bun` references in scripts and configs
- Any `Bundlebun` references in your code

## Acknowledgements

Bun binaries are sourced directly from [oven-sh/bun releases](https://github.com/oven-sh/bun/releases). [Bun](https://bun.sh) was created by Jarred Sumner ([@jarred-sumner](https://github.com/jarred-sumner)) and distributed under MIT.

Big thanks to Jason Meller ([@terracatta](https://github.com/terracatta)) for his work on Bun's Ruby on Rails ecosystem integration—jsbundling-rails, cssbundling-rails, turbo-rails, stimulus-rails, and ExecJS support—in [this Pull Request](https://github.com/rails/rails/pull/49241).

## Contributing

Make sure you have up-to-date Ruby. Run `bin/setup` to install gems, install [lefthook](https://github.com/evilmartians/lefthook), and run `rake bundlebun:download` to fetch a local Bun build for tests.

Run `rake rspec` to check tests. Open an issue or a PR.

## License

The gem is available as open source under the terms of the MIT License. See [LICENSE.txt](LICENSE.txt).
