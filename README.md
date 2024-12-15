# bundlebun

**bundlebun bundles [Bun](https://bun.sh), a fast JavaScript runtime, package manager, and builder, with your Ruby and Rails applications**. No need to use Docker, devcontainers, `curl ... | sh`, or `brew`.

## Quickstart

Within your Ruby or Rails project:

```sh
bundle add bundlebun
rake bun:install
```

and then

```sh
bin/bun ...
```

## Rationale

**Modern frontend setup is needlessly complex** and may involve a lot of setup and maintenance. Developers need _at the very least_ a JavaScript runtime (typically, Node.js), a package manager (could be npm, yarn, or pnpm), and a build tool (Vite, Webpack, esbuild, Parcel—dozens of them).

- One way forward is to dockerize development environments, creating unnecessary headaches for the development team—both frontend and backend engineers, especially if the team is not that large and the project is not that complex.
- Another is to declare front-ops bankruptcy and pursue the "no-build" route.

**What if we can simplify?** **Bun** is a **JavaScript runtime**, optimized for speed and developer experience. Bun is _also_ a fast JavaScript **package manager**. Bun is _also_ a **build tool**. Bun is also distributed as a single executable file.

But Bun still requires [some installation](https://bun.sh/docs/installation), and we need to ensure everyone in the team uses the same version.

How about we just pack it into a Ruby gem as a binary and allow developers to stay updated—every time a new Bun version is out—or freeze their desired version within their Ruby project. There are no setups, large READMEs with instructions, and no enforcing the Docker workflow.

**Meet bundlebun**. With fast JavaScript runtime and a package manager included you can even skip on the build tool and use Bun itself.

## Install

bundlebun gem releases include a binary distribution of Bun for each supported Bun platform (macOS, Linux, Windows) and architectures.

First, add it to your `Gemfile`:

```ruby
gem "bundlebun"
```

and

```sh
bundle install
```

or just

```sh
bundle add bundlebun
```

Next, run

```sh
rake bun:install
```

The task will install a binstub (`bin/bun`) that you can use to run Bun commands: try running `bin/bun` or `bin/bun --version`.

You should use `bin/bun` in your scripts, including your local runners like `Procfile.dev` or `Procfile`, and `package.json`—if you had a call to `node` or `bun` in the `scripts` section there.

Next, the Rake task will try to detect the integrations we need to install based on the classes and modules Rake can see in your project. We'll follow with integrations:

### Integrations

Running `rake bun:install` tries to detect already-loaded gems and run the corresponding installation tasks.

Alternatively, you can ensure an integration is loaded and the necessary modules are patched by calling methods that look like `Bundlebun::Integration::IntegrationName.bun!`: more on that below.

#### Ruby on Rails: cssbundling and jsbundling

[cssbundling](https://github.com/rails/cssbundling-rails) and [jsbundling](https://github.com/rails/jsbundling-rails) are Rails gems that support the traditional CSS and JS building pipeline for Ruby on Rails.

Be sure to check both gems on documentation for bootstrapping your frontend build pipeline, as bundlebun supports them instead of duplicating approaches. cssbundling, for instance, includes an excellent sample build configuration for Bun.

The bundlebun integration would be installed automatically, or you can run

```sh
rake bun:install:rails
```

manually. The task ensures a `bin/bun` binstub and installs an initializer/task of sorts to ensure both build-related gems use our bundled version of Bun.

Alternatively, you can call

```ruby
Bundlebun::Integrations::Cssbundling.bun!
Bundlebun::Integrations::Jsbundling.bun!
```

in one of your project's rakefiles.

#### vite-ruby and vite-rails

[vite-ruby](https://github.com/ElMassimo/vite_ruby) and [vite-rails](https://vite-ruby.netlify.app/) are gems that make Ruby and Rails integration with [Vite](https://vite.dev/), a great JavaScript build tool and platform, seamless and easy.

The bundlebun integration would be installed automatically, or you can run

```sh
rake bun:install:vite
```

That will ensure that you have a `bin/bun` binstub.

Next, we'll install a custom `bin/vite` binstub (otherwise, ruby-vite won't be able to sense bundlebun presence); the original file, if present, would be backed up to `bin/vite-backup`.

Finally, we'll put an initializer that forces vite-ruby to use bundlebun. Alternatively, you can call

```ruby
Bundlebun::Integrations::ViteRuby.bun!
```

yourself.

#### ExecJS

[ExecJS](https://github.com/rails/execjs) runs JavaScript code straight from Ruby. For that, it supports a bunch of runtimes it could launch—and get a result. The Bun runtime already exists for ExecJS, and we just need to ensure it uses the bundled one.

The bundlebun integration would be installed automatically, or you can run

```sh
rake bun:install:execjs
```

That would create an initializer that would redefine the Bun runtime for ExecJS and force its usage to be the default. Alternatively, you can call

```ruby
Bundlebun::Integrations::ExecJS.bun!
```

### Notes on `gem install`

bundlebun is designed to be used with Bundler: installed in specific projects, and launched via `bin/bun` or integrations.

If you install the gem globally, you _won't see the `bun` executable_ as a wrapper for a bundled Bun runtime; instead, it would be called `bundlebun`. This is done to avoid possible conflicts in your `$PATH` with a "real" Bun runtime you might have installed: if Ruby gem-generated binstubs are in that path before your Bun runtime, you won't easily run it. And that is bundlebun is not greedy with the `bun` executable name.

If you wish to run Bun runtime globally using this gem, a simple symlink or a wrapper script will do, but the gem won't act destructively.

## Usage

### Binstub

The easiest way to interact with bundled Bun is via the binstub at `bin/bun`. It will launch the bundled version of Bun with the arguments provided:

```sh
> bin/bun
Bun is a fast JavaScript runtime, package manager, bundler, and test runner. (1.1.38+bf2f153f5)

Usage: bun <command> [...flags] [...args]

...
```

### Return codes

Note that with this or any other option to run Bun, bundlebun will return the error code `127` if the executable is not found.

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

The easiest way to call Bun from Ruby would be `Bundlebun.call`:

```ruby
Bundlebun.call("outdated")
Bundlebun.call(["add", "postcss"])
```

Check out the RDoc documentation for `Bundlebun::Runner` for helper methods. Some of the most useful ones:

- `Bundlebun::Runner.binary_path`: returns the full path to the bundled Bun library.
- `Bundlebun::Runner.binary_path_exist?`: checks if that binary even exists.
- `Bundlebun::Runner.binstub_exist?`: checks if the binstub exists.
- `Bundlebun::Runner.binstub_or_binary_path`: returns the optimal way to run bundled Bun: a path to binstub or a full path to the binary.

## Versioning

bundlebun uses the `#{bundlebun.version}.#{bun.version}` versioning scheme.

Meaning: gem bundlebun version `0.1.0.1.1.38` is a distribution that includes a gem with its own code version `0.1.0` and a Bun runtime with version `1.1.38`.

bundlebun is supposed to automatically push new gem versions when there is a new Bun release.

You can lock the exact version number in your `Gemfile`, or leave the version unspecified and update it as you wish.

## Uninstall

To uninstall, remove the gem:

```sh
bundle remove bundlebun
```

Or remove it from your `Gemfile`.

Next, remove the integrations you have in place:

- `bin/bun`
- Delete `bin/vite` if exists or restore it from `bin/vite-backup`
- Delete `tasks/bundlebun.rake` if exists
- Delete `config/initializers/bundlebun-vite.rb` if exists
- Delete `config/initializers/bundlebun-execjs.rb` if exists
- Search for `bin/bun` mentions in your code and configs
- Search for `Bundlebun` mentions in your code.

## Acknowledgements

bundlebun gem downloads contain binary distributions of Bun available directly from https://github.com/oven-sh/bun/releases.

[Bun](https://bun.sh) was created Jarred Sumner [@jarred-sumner](https://github.com/jarred-sumner) and co. and is distributed under MIT. Check their [LICENSE](https://github.com/oven-sh/bun/blob/main/LICENSE.md).

Big thanks to Jason Meller [@terracatta](https://github.com/terracatta) for his work on integrating Bun into the Rails ecosystem: jsbundling-rails support, cssbundling-rails support with a proper build configuration, turbo-rails and stimulus-rails support, ExecJS support. See this [Pull Request](https://github.com/rails/rails/pull/49241).

## Contributing

Make sure you have up-to-date Ruby. Run `bundle install`. Run `rake bundlebun:download` to fetch a local version of Bun for tests. `rake rspec` to check if all tests pass.

Open an issue or a PR.

## License

The gem is available as open source under the terms of the MIT License.

See [LICENSE.txt](LICENSE.txt).
