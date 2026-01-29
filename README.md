# bundlebun

**bundlebun bundles [Bun](https://bun.sh), a fast JavaScript runtime, package manager, and builder, with your Ruby and Rails applications**. No need to use Docker, devcontainers, `curl ... | sh`, or `brew`.

[![GitHub Release](https://img.shields.io/github/v/release/yaroslav/bundlebun)](https://github.com/yaroslav/bundlebun/releases)
[![Docs](https://img.shields.io/badge/yard-docs-blue.svg)](https://rubydoc.info/gems/bundlebun)

<div align="center">
  <img src="https://raw.githubusercontent.com/yaroslav/bundlebun/refs/heads/main/assets/mr-bundlebun-512.png" width="256" height="256" alt="Mr. Bundlebun">
</div>

## Rationale

**Modern frontend setup is needlessly complex** and may involve a lot of maintenance. Developers need _at the very least_ a JavaScript runtime (typically, Node.js), a package manager (could be npm, yarn, or pnpm), and a build tool (Vite, Webpack, esbuild, Parcel—dozens of them).

- One way forward is to dockerize development environments, creating unnecessary headaches for the development team—both frontend and backend engineers (especially if the team is not that large and the project is not that complex).
- Another approach is to declare front-ops bankruptcy and pursue the "no-build" route.

**What if we could simplify this?** **Bun** is a **JavaScript runtime**, optimized for speed and developer experience. Bun is _also_ a fast JavaScript **package manager**. Bun is _also_ a **build tool**. Bun is also distributed as a single executable file.

However, Bun still requires [some installation](https://bun.sh/docs/installation), and we need to make sure everyone on the team is using the same version.

So, how about we just pack it into a Ruby gem as a binary and allow developers to stay updated? Then, we'll be ready every time a new Bun version is out—or the user can freeze their desired version within their Ruby project. There are no setups, large READMEs with instructions, and no enforcing the Docker workflow.

**Enter bundlebun**. With a fast JavaScript runtime and a package manager included, you can even skip the build tool and use Bun itself.

## Quickstart

Starting with your Ruby or Rails project, no Bun or anything like that required:

```sh
bundle add bundlebun
rake bun:install
```

and then:

```sh
> bin/bun ...
Bun is a fast JavaScript runtime, package manager, bundler, and test runner. (1.1.38+bf2f153f5)

Usage: bun <command> [...flags] [...args]
...
```

## Install

bundlebun gem releases include a binary distribution of Bun for each supported Bun platform (macOS, Linux, Windows) and architecture. bundlebun is tested for Unix-like environments and Windows.

First, add it to your `Gemfile`. Make sure to add it _after_ your existing frontend- and build-related librares:

```ruby
# ...

# Frontend-related gems go here
# For example, Vite integration
# gem "vite_rails"

gem "bundlebun"
```

and:

```sh
bundle install
```

(or just):

```sh
bundle add bundlebun
```

_If you're seeing a message like `Could not find gems matching 'bundlebun' valid for all resolution platforms
(aarch64-linux, aarch64-linux-gnu <...> )`, [check this article](https://github.com/yaroslav/bundlebun/wiki/Could-not-find-gems-matching-'bundlebun'-valid-for-all-resolution-platforms)._

Next, run:

```sh
rake bun:install
```

The task will install a binstub (`bin/bun`) that you can use to run Bun commands; try running `bin/bun` or `bin/bun --version`.

If `package.json` is present, the installer will offer to migrate your scripts to use `bin/bun` (e.g., `bun` → `bin/bun`, `npx` → `bin/bun x`). You can also run `rake bun:install:package` manually later.

Similarly, if `Procfile` or `Procfile.*` files are present, the installer will offer to migrate those as well. Run `rake bun:install:procfile` manually if needed.

_Windows tip:_ If you're on Windows, the `bin\bun.cmd` file will be created. If you've joined an existing project where only the Unix-like binstub exists at that location, just run `rake bun:install` again.

Next, the Rake task will try to detect the integrations we need to install based on the classes and modules Rake can see in your project. We'll continue with integrations.

**By default, on load, bundlebun:**

- adds the path to the bundled `bun` executable to the start of your application's `PATH`. That simplifies the integration in cases where we don't really need to monkey-patch a lot of code, and we just need to make sure it "sees" our `bun` executable as available.
- tries to detect and load all possible integrations.

### Integrations

Usually, if you've placed `gem 'bundlebun'` after your frontend-related gems in the `Gemfile`, and did `rake bun:install`, the integrations should all be working out of the box.

Alternatively, you can ensure an integration is loaded and the necessary modules are patched by calling methods that look like `Bundlebun::Integration::IntegrationName.bun!`. See the API documentation for that.

#### vite-ruby and vite-rails

[vite-ruby](https://github.com/ElMassimo/vite_ruby) and [vite-rails](https://vite-ruby.netlify.app/) are gems that make Ruby and Rails integration with [Vite](https://vite.dev/), a great JavaScript build tool and platform, seamless and easy.

The bundlebun integration would be installed automatically with `rake bun:install`, or you can run:

```sh
rake bun:install:vite
```

That will make sure you have a `bin/bun` binstub. Next, we'll install a custom `bin/bun-vite` binstub to use in build scripts. The installer Rake task will create a new `vite.json` file if it does not exist yet, or force the existing one to use that binstub for building. See the [Vite Ruby configuration manual](https://vite-ruby.netlify.app/config/index.html) for details on `vite.json`.

Make sure you have `gem bundlebun` mentioned _after_ all the vite-related gems in your `Gemfile`. If you want to keep integrations to a minimum, and only enable them manually, use the following to manually turn on the bundlebun monkey-patching for vite-ruby:

```ruby
Bundlebun::Integrations::ViteRuby.bun!
```

#### Ruby on Rails: cssbundling and jsbundling

[cssbundling](https://github.com/rails/cssbundling-rails) and [jsbundling](https://github.com/rails/jsbundling-rails) are Rails gems that support the traditional CSS and JS building pipeline for Ruby on Rails.

Be sure to check both gems for documentation on bootstrapping your frontend build pipeline (as bundlebun supports them) instead of duplicating approaches. cssbundling, for instance, includes an excellent sample build configuration for Bun.

To quote their READMEs, try this for cssbundling:

```sh
bundle add cssbundling-rails
bin/rails css:install:[tailwind|bootstrap|bulma|postcss|sass]
bin/rails css:build
```

and this jsbundling:

```sh
bundle add jsbundling-rails
bin/rails javascript:install:bun
```

To make sure the bundlebun integration is installed (although the default `rake bun:install` should detect everything just fine), run

```sh
rake bun:install:bundling-rails
```

The task makes sure a `bin/bun` binstub exists and installs an Rake task hack of sorts to ensure both build-related gems use our bundled version of Bun.

#### ExecJS

[ExecJS](https://github.com/rails/execjs) runs JavaScript code straight from Ruby. To do so, it supports a bunch of runtimes it can launch—and get a result. The Bun runtime support already exists for ExecJS; we just need to ensure it uses the bundled one.

The bundlebun integration will work automatically if bundlebun is loaded after ExecJS in the `Gemfile`.

Alternatively, you can load the monkey-patch manually:

```ruby
Bundlebun::Integrations::ExecJS.bun!
```

## Usage

### Binstub

The easiest way to interact with bundled Bun is via the binstub at `bin/bun`; it will launch the bundled version of Bun with the arguments provided:

```sh
> bin/bun
Bun is a fast JavaScript runtime, package manager, bundler, and test runner. (1.1.38+bf2f153f5)

Usage: bun <command> [...flags] [...args]

...
```

### `PATH`

The bundlebun gem adds the directory with a binary Bun distribution to your `PATH`: prepends it there, to be exact. That helps existing tools that can detect the presence of `bun` executable to find it and work with no further setup or monkey-patching.

### Rake

Alternatively, you can use a Rake task. The syntax is far from perfect, but that's a limitation of Rake. You need to add quotes around the parameters and put them into square brackets. If you cannot install the binstub, though, might be your option.

```
rake bun[command]  # Run bundled Bun with parameters
```

```sh
> rake "bun[outdated]"
bun outdated v1.1.38 (bf2f153f)
...
```

### Ruby

**Check bundlebun API: https://rubydoc.info/gems/bundlebun**.

The easiest way to call Bun from Ruby would be `Bundlebun.call`:

```ruby
Bundlebun.call("outdated") # => `bun outdated`
Bundlebun.call(["add", "postcss"]) # => `bun add postcss`
```

Check out the [API documentation](https://rubydoc.info/gems/bundlebun) on `Bundlebun::Runner` for helper methods.

## Versioning

bundlebun uses the `#{bundlebun.version}.#{bun.version}` versioning scheme. Meaning: gem bundlebun version `0.1.0.1.1.38` is a distribution that includes a gem with its own code version `0.1.0` and a Bun runtime with version `1.1.38`.

bundlebun is designed to automatically push new gem versions when there is a new Bun release. That said, you can lock the exact version number in your `Gemfile`, or leave the version unspecified and update it as you wish.

## Uninstall

To uninstall, remove the gem:

```sh
bundle remove bundlebun
```

Or remove it from your `Gemfile` and run bundler.

Next, remove the integrations you might have in place:

- `bin/bun`
- Delete `bin/bun-vite` if exists
- Delete `tasks/bundlebun.rake` if exists
- Search for `bin/bun` mentions in your code and configs
- Search for `Bundlebun` mentions in your code.

## Acknowledgements

bundlebun gem downloads contain binary distributions of Bun available directly from https://github.com/oven-sh/bun/releases.

[Bun](https://bun.sh) was created by Jarred Sumner [@jarred-sumner](https://github.com/jarred-sumner) & co. and is distributed under MIT. Check their [LICENSE](https://github.com/oven-sh/bun/blob/main/LICENSE.md).

Big thanks to Jason Meller [@terracatta](https://github.com/terracatta) for his work on integrating Bun into the Ruby on Rails ecosystem: jsbundling-rails support, cssbundling-rails support with a proper build configuration, turbo-rails and stimulus-rails support, ExecJS support. See this [Pull Request](https://github.com/rails/rails/pull/49241).

## Contributing

Make sure you have up-to-date Ruby. Run `bin/setup` to install the nesessary gems, install [lefthook](https://github.com/evilmartians/lefthook) and run `rake bundlebun:download` to fetch a local version of Bun for tests.

`rake rspec` to check if all tests pass.

Open an issue or a PR.

## License

The gem is available as open source under the terms of the MIT License.

See [LICENSE.txt](LICENSE.txt).
