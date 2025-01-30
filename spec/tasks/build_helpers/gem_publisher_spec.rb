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
end
