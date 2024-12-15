# frozen_string_literal: true

require_relative '../../../tasks/build_helpers'

require 'ostruct'
require 'octokit'

RSpec.describe BuildHelpers::BunVersion do
  let(:version_checker) { described_class.new }
  let(:mock_client) { instance_double(Octokit::Client) }

  before do
    allow(Octokit::Client).to receive(:new).and_return(mock_client)
  end

  describe 'detecting the latest version' do
    it 'returns Bun version from GitHub release' do
      allow(mock_client).to receive(:latest_release)
        .with(BuildHelpers::BUN_REPO)
        .and_return(OpenStruct.new(tag_name: 'bun-v1.0.0'))

      expect(version_checker.latest_bun_repo_version).to eq('1.0.0')
    end

    it 'returns gem version from GitHub release' do
      allow(mock_client).to receive(:latest_release)
        .with(BuildHelpers::GEM_REPO)
        .and_return(OpenStruct.new(tag_name: 'bundlebun-v0.1.0.1.0.0'))

      expect(version_checker.latest_gem_version).to eq('0.1.0.1.0.0')
    end

    it 'returns bundled bun gem version from GitHub release' do
      allow(mock_client).to receive(:latest_release)
        .with(BuildHelpers::GEM_REPO)
        .and_return(OpenStruct.new(tag_name: 'bundlebun-v0.1.0.1.0.0'))

      expect(version_checker.latest_bun_gem_version).to eq('1.0.0')
    end
  end

  describe 'detecting gem vs. Bun version changes' do
    before do
      allow(mock_client).to receive(:latest_release)
        .with(BuildHelpers::BUN_REPO)
        .and_return(OpenStruct.new(tag_name: 'bun-v1.1.0'))
    end

    it 'returns true when versions differ' do
      allow(mock_client).to receive(:latest_release)
        .with(BuildHelpers::GEM_REPO)
        .and_return(OpenStruct.new(tag_name: 'bundlebun-v0.1.0.1.0.0'))
      expect(version_checker.version_changed?).to be true
    end

    it 'returns false when versions match' do
      allow(mock_client).to receive(:latest_release)
        .with(BuildHelpers::GEM_REPO)
        .and_return(OpenStruct.new(tag_name: 'bundlebun-v0.1.0.1.1.0'))
      expect(version_checker.version_changed?).to be false
    end
  end
end
