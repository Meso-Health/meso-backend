require 'rails_helper'

RSpec.describe 'FactoryBot factories', :upkeep do
  it 'checks all the factories are valid' do
    FactoryBot.lint traits: true
  end
end
