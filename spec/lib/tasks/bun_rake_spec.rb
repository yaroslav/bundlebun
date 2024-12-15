# frozen_string_literal: true

RSpec.describe 'rake bun' do
  let(:rake_app) { Rake::Application.new }
  let(:task_name) { :bun }
  let(:binary_path) { Bundlebun::Runner.binary_path }

  before(:each) do
    Rake.application = rake_app
    require 'bundlebun'
    Bundlebun.load_tasks

    allow_any_instance_of(Bundlebun::Runner).to receive(:exec)
    allow(File).to receive(:exist?).with(binary_path).and_return(true)
  end

  it 'has a bun task' do
    expect(Rake::Task.task_defined?(task_name)).to be true
  end

  describe 'command execution' do
    it 'executes bun with no arguments' do
      expect_command_execution(binary_path)
      Rake::Task[task_name].invoke
    end

    it 'executes bun with command string' do
      expect_command_execution("#{binary_path} install package")
      Rake::Task[task_name].invoke('install package')
    end

    it 'handles command with quotes' do
      expect_command_execution(%{#{binary_path} -e 'console.log(2+2)'})
      Rake::Task[task_name].invoke("-e 'console.log(2+2)'")
    end
  end

  private

  def expect_command_execution(command)
    expect_any_instance_of(Bundlebun::Runner).to receive(:exec).with(command)
  end
end
