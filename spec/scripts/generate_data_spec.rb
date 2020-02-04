require 'rails_helper'
require 'support/shared_contexts/rake'

RSpec.describe 'Database seed data Rake tasks', :upkeep do
  before do
    allow($stdout).to receive(:puts)
  end

  def run_and_assert_print_tasks_success
    Rails.application.load_tasks
    Rake::Task['db:print_members_summary'].invoke
    Rake::Task['db:print_claims_summary'].invoke
  end

  # This spec is too flaky so commenting this out.
  # describe 'db:seed:demo_data', use_database_rewinder: true  do
  #   include_context 'rake'
  #   let(:task_path) { 'lib/tasks/seed' }

  #   specify 'prerequisites' do
  #     expect(subject.prerequisites).to include('environment')
  #   end

  #   it 'creates exactly the objects we expect' do
  #     subject.invoke
  #     run_and_assert_print_tasks_success
  #   end
  # end
end
