require 'factory_bot'

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end

FactoryBot.define do
  to_create do |instance|
    if PaperTrail.enabled?
      PaperTrail.without_versioning { instance.save! }
    else
      instance.save!
    end
  end
end
