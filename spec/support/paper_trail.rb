require 'paper_trail/frameworks/rspec'

# Force request specs to run with versioning on
RSpec.configure do |config|
  config.define_derived_metadata(type: :request) do |metadata|
    metadata[:versioning] = true
  end
end
