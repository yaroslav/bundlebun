## [0.2.2] - 2025-12-07

- Bundler 4.0 spec fixes
- Update dependencies

## [0.2.1] - 2025-05-28

- Update dependencies

## [0.2.0] - 2025-01-30

- It is now recommended to include `gem bundlebun` after other existing frontend-related gems in your `Gemfile`. That removes the need to install one-liner initializer monkeypatches for most cases. The gem detects and loads all integrations when loaded. Alternatively, the developer can call integration monkey-patches (`Bundlebun::Integrations::Something.bun!`) directly.
- bundlebun now adds the bundled bun executable to `PATH`, both on Unix-like and Windows environments. This improves the support for other frontend-related libraries and gems: we don't have to monkey-patch libraries _all the time_, just when we need it.
- While there still might be some issues, I am trying to ensure proper Windows (non-WSL) support for this gem, for a plug&play experience for Windows Ruby developers.
- The vite-ruby integration is reworked. We don't touch the existing `bin/vite` binstub anymore. Instead, we install `bin/bun-vite` that will run Vite with Bun and use it with ruby-vite's `vite.json`. We modify the existing config file, or install a sample one.
- The `bun:install:rails` Rake task is now `bun:install:bundling-rails`, as it only activates from `bun:install` if Cssbundling or Jsbundling are detected, does not have to do a lot with Rails itself.
- For Windows, the gem now installs a `bin/bun.cmd` binstub, as well as `bin/bun-vite.cmd` for use with vite-ruby. If the integration was already installed, but there are no Windows binstubs in sight, run `rake bun:install` again.
- The ExecJS test is now a proper integration test, like the other integration tests.
- bundlebun is now properly tested on Windows (Windows Server 2025 on GitHub Actions).

## [0.1.2] - 2024-12-21

- Integration specs now test bundlebun + Bun against vite-ruby and cssbundling-rails + jsbundling-rails with positive real-world scenarios
- Minor internal task changes
- No major code changes

## [0.1.1] - 2024-12-17

- Switch to Yard documentation format from RDoc
- No major code changes

## [0.1.0] - 2024-12-15

- Initial release
