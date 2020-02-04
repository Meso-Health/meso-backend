Rails.application.console do
  logger = ActiveSupport::Logger.new(STDOUT)
  logger.level = Logger::DEBUG
  ActiveRecord::Base.logger = logger
end
