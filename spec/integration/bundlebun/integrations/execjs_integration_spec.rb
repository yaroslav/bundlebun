# frozen_string_literal: true

require 'execjs'

RSpec.describe Bundlebun::Integrations::ExecJS, type: :integration do
  describe 'with Bun runtime' do
    before do
      Bundlebun::Integrations::ExecJS.bun!
    end

    it 'successfully connects to Bun runtime' do
      version = ExecJS.eval('Bun.version')
      expect(version).to be_a(String)
      expect(version).to match(/\d+\.\d+\.\d+/)
    end

    it 'sets Bun as the runtime' do
      expect(ExecJS.runtime.name).to eq('Bun.sh')
    end
  end
end
