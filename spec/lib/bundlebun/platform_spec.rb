# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bundlebun::Platform do
  describe 'with Windows detection' do
    subject { described_class.windows? }

    context 'when running on Windows' do
      before do
        described_class.remove_instance_variable(:@windows)

        stub_const('RbConfig', Module.new)
        stub_const('RbConfig::CONFIG', {
          'host_os' => 'mingw32'
        })
      end

      it { is_expected.to be true }
    end

    context 'when running on non-Windows system' do
      before do
        described_class.remove_instance_variable(:@windows)

        stub_const('RbConfig', Module.new)
        stub_const('RbConfig::CONFIG', {
          'host_os' => 'darwin19.0.0'
        })
      end

      it { is_expected.to be false }
    end
  end
end
