require 'rails_helper'

RSpec.describe 'Dragonfly configuration' do
  let(:klass) do
    Class.new do
      attr_accessor :file_uid, :file_name

      extend Dragonfly::Model
      dragonfly_accessor :file
    end
  end
  let(:model) do
    TestModel.new.tap do |m|
      m.file = File.open(Rails.root.join("spec/factories/members/photo#{rand(12)+1}.jpg"))
      m.file.save!
    end
  end
  let(:url) { model.file.thumb('200x200').url }

  before do
    stub_const('TestModel', klass)
  end

  it 'generates job URLs prefixed under /dragonfly' do
    expect(url).to match(/\/dragonfly\/media\//)
  end

  it 'routes job URLs correctly', type: :request do
    get url
    expect(response).to be_successful
  end

  it 'disallows generating a URL to the original media' do
    expect(model.file.url).to be_nil
  end
end
