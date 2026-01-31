# frozen_string_literal: true

require_relative '../../../tasks/build_helpers'

RSpec.describe BuildHelpers::GemPublisher do
  let(:version) { '0.1.0.1.0.0' }
  let(:github_client) { instance_double(Octokit::Client) }
  let(:version_checker) { instance_double(BuildHelpers::BunVersion) }
  let(:release) { instance_double('Release', url: 'https://api.github.com/repos/user/repo/releases/1') }
  let(:publisher) { described_class.new(version) }
  let(:gem_files) { ['bundlebun-0.1.0.1.0.0-x86_64-linux.gem'] }
  let(:tag) { "bundlebun-v#{version}" }

  before do
    allow(Octokit::Client).to receive(:new).and_return(github_client)
    allow(BuildHelpers::BunVersion).to receive(:new).and_return(version_checker)
    allow(version_checker).to receive(:latest_bun_repo_version).and_return('1.0.0')

    allow(File).to receive(:exist?).and_return(true)
    allow(File).to receive(:readlines)
      .with('built_gems.txt')
      .and_return(gem_files)

    ENV['GEM_HOST_API_KEY'] = 'fake_rubygems_key'
  end

  after do
    ENV.delete('GEM_HOST_API_KEY')
  end

  context 'when all validations pass' do
    before do
      allow(github_client).to receive(:create_release)
        .with(
          BuildHelpers::GEM_REPO,
          tag,
          hash_including(
            name: "bundlebun v#{version}",
            draft: false,
            prerelease: false,
            target_commitish: 'main'
          )
        )
        .and_return(release)

      allow(github_client).to receive(:upload_asset)
        .with(
          release.url,
          anything,
          hash_including(content_type: 'application/x-ruby-gem')
        )

      allow(publisher).to receive(:system)
        .with(any_args)
        .and_return(true)
    end

    it 'creates a GitHub release' do
      expect(github_client).to receive(:create_release)
      publisher.publish
    end

    it 'uploads gem files as release assets' do
      expect(github_client).to receive(:upload_asset)
        .exactly(gem_files.length).times
      publisher.publish
    end

    it 'publishes gems to RubyGems' do
      gem_files.each do |gem_file|
        expect(publisher).to receive(:system)
          .with("gem push --key fake_rubygems_key #{gem_file}", exception: true)
      end
      publisher.publish
    end
  end

  context 'when validations fail' do
    it 'raises error when RubyGems API key is missing' do
      ENV.delete('GEM_HOST_API_KEY')
      expect { publisher.publish }.to raise_error(
        BuildHelpers::GemPublisher::PublishError,
        'GEM_HOST_API_KEY not provided'
      )
    end

    it 'raises error when built_gems.txt is missing' do
      allow(File).to receive(:exist?)
        .with('built_gems.txt')
        .and_return(false)

      expect { publisher.publish }.to raise_error(
        BuildHelpers::GemPublisher::PublishError,
        'No built_gems.txt found'
      )
    end

    it 'raises error when built_gems.txt is empty' do
      allow(File).to receive(:readlines)
        .with('built_gems.txt')
        .and_return([])

      expect { publisher.publish }.to raise_error(
        BuildHelpers::GemPublisher::PublishError,
        'No built_gems.txt found'
      )
    end
  end

  context 'when GitHub operations fail' do
    it 'raises error on release creation failure' do
      allow(github_client).to receive(:create_release)
        .and_raise(Octokit::Error.new)

      expect { publisher.publish }.to raise_error(
        BuildHelpers::GemPublisher::PublishError,
        /Failed to create GitHub release/
      )
    end

    it 'raises error on asset upload failure' do
      allow(github_client).to receive(:create_release)
        .and_return(release)
      allow(github_client).to receive(:upload_asset)
        .and_raise(Octokit::Error.new)

      expect { publisher.publish }.to raise_error(
        BuildHelpers::GemPublisher::PublishError,
        /Failed to create GitHub release/
      )
    end
  end

  context 'when RubyGems publishing fails' do
    before do
      allow(github_client).to receive(:create_release)
        .and_return(release)
      allow(github_client).to receive(:upload_asset)
    end

    it 'raises error on gem push failure' do
      allow(publisher).to receive(:system)
        .and_raise(StandardError.new("Gem push failed"))

      expect { publisher.publish }.to raise_error(
        BuildHelpers::GemPublisher::PublishError,
        /Failed to publish to RubyGems/
      )
    end
  end

  describe 'extracting a CHANGELOG part for the release notes' do
    let(:changelog_content) do
      <<~CHANGELOG
        ## [Unreleased]

        - Upcoming feature that is not yet released
        - Another upcoming feature

        ## [0.3.0] - 2026-01-29

        - New `rake bun:install:package` task: automatically migrates `package.json` scripts
        - New `rake bun:install:procfile` task: automatically migrates `Procfile` files
        - Both tasks are automatically invoked by `rake bun:install`

        ## [0.2.0] - 2025-01-30

        - Major update with new features
        - Breaking changes included

        ## [0.1.0] - 2024-12-15

        - Initial release
      CHANGELOG
    end

    let(:tmpfile) do
      file = Tempfile.new(['CHANGELOG', '.md'])
      file.write(changelog_content)
      file.close
      file
    end

    after { tmpfile.unlink }

    before do
      allow(File).to receive(:expand_path)
        .with('../../CHANGELOG.md', anything)
        .and_return(tmpfile.path)
    end

    it 'extracts changelog content for a base version' do
      result = publisher.send(:extract_changelog_for_version, '0.3.0')

      expect(result).to include('rake bun:install:package')
      expect(result).to include('rake bun:install:procfile')
      expect(result).to include('Both tasks are automatically invoked')
    end

    it 'extracts changelog content for a composite version' do
      result = publisher.send(:extract_changelog_for_version, '0.3.0.1.1.38')

      expect(result).to include('rake bun:install:package')
      expect(result).not_to include('Unreleased')
      expect(result).not_to include('Major update')
    end

    it 'extracts the last version in changelog' do
      result = publisher.send(:extract_changelog_for_version, '0.1.0')

      expect(result).to eq('- Initial release')
    end

    it 'returns nil for non-existent version' do
      result = publisher.send(:extract_changelog_for_version, '9.9.9')

      expect(result).to be_nil
    end

    it 'does not include content from other versions' do
      result = publisher.send(:extract_changelog_for_version, '0.2.0')

      expect(result).to include('Major update')
      expect(result).not_to include('Initial release')
      expect(result).not_to include('rake bun:install:package')
    end

    context 'when changelog file does not exist' do
      before do
        allow(File).to receive(:expand_path)
          .with('../../CHANGELOG.md', anything)
          .and_return('/nonexistent/path/CHANGELOG.md')
      end

      it 'returns nil' do
        result = publisher.send(:extract_changelog_for_version, '0.3.0')

        expect(result).to be_nil
      end
    end

    context 'when changelog has malformed content' do
      let(:changelog_content) { 'This is not a valid changelog format' }

      it 'returns nil' do
        result = publisher.send(:extract_changelog_for_version, '0.3.0')

        expect(result).to be_nil
      end
    end
  end
end
