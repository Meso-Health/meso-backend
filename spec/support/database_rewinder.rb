RSpec.configure do |config|
  config.around :example, use_database_rewinder: true do |example|
    self.use_transactional_tests = false
    example.run
    DatabaseRewinder.clean
  end
end
