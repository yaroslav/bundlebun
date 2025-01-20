# frozen_string_literal: true

RSpec.describe Bundlebun::Integrations do
  describe '.bun!' do
    module TestModule; end

    before do
      # Add our test module to the integrations
      Bundlebun::Integrations.const_set(:TestModule, TestModule)

      # Our real integrations
      allow(Bundlebun::Integrations::Cssbundling).to receive(:bun!)
      allow(Bundlebun::Integrations::Jsbundling).to receive(:bun!)
      allow(Bundlebun::Integrations::ExecJS).to receive(:bun!)
      allow(Bundlebun::Integrations::ViteRuby).to receive(:bun!)
    end

    after do
      Bundlebun::Integrations.send(:remove_const, :TestModule)
    end

    it 'calls bun! on each integration module' do
      described_class.bun!

      expect(Bundlebun::Integrations::Cssbundling).to have_received(:bun!)
      expect(Bundlebun::Integrations::Jsbundling).to have_received(:bun!)
      expect(Bundlebun::Integrations::ExecJS).to have_received(:bun!)
      expect(Bundlebun::Integrations::ViteRuby).to have_received(:bun!)
    end

    it 'does not fail when module does not respond to bun!' do
      expect { described_class.bun! }.not_to raise_error
    end
  end
end
