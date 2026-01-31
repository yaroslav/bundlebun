# frozen_string_literal: true

require 'active_support'
require 'active_support/notifications'

RSpec.describe 'ActiveSupport::Notifications instrumentation', type: :integration do
  let(:binary_path) { Bundlebun::Runner.binary_path }
  let(:events) { [] }

  before do
    allow(File).to receive(:exist?).with(binary_path).and_return(true)
    allow(Kernel).to receive(:system).and_return(true)
    allow(Kernel).to receive(:exec)
  end

  describe 'system.bundlebun' do
    before do
      ActiveSupport::Notifications.subscribe('system.bundlebun') do |*args|
        events << ActiveSupport::Notifications::Event.new(*args)
      end
    end

    after do
      ActiveSupport::Notifications.unsubscribe('system.bundlebun')
    end

    it 'emits an event with command payload' do
      Bundlebun.system('install')

      expect(events.size).to eq(1)
      expect(events.first.name).to eq('system.bundlebun')
      expect(events.first.payload).to eq({command: 'install'})
    end

    it 'includes timing information' do
      Bundlebun.system('build')

      expect(events.first.duration).to be >= 0
    end

    it 'works with array arguments' do
      Bundlebun.system(['add', 'postcss'])

      expect(events.first.payload).to eq({command: ['add', 'postcss']})
    end
  end

  describe 'exec.bundlebun' do
    before do
      ActiveSupport::Notifications.subscribe('exec.bundlebun') do |*args|
        events << ActiveSupport::Notifications::Event.new(*args)
      end
    end

    after do
      ActiveSupport::Notifications.unsubscribe('exec.bundlebun')
    end

    it 'emits an event with command payload' do
      Bundlebun.call('install')

      expect(events.size).to eq(1)
      expect(events.first.name).to eq('exec.bundlebun')
      expect(events.first.payload).to eq({command: 'install'})
    end

    it 'works with array arguments' do
      Bundlebun.call(['run', 'dev'])

      expect(events.first.payload).to eq({command: ['run', 'dev']})
    end
  end
end
