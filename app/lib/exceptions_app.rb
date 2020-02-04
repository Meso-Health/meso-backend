# Based on yuri24's rambulance
# https://github.com/yuki24/rambulance/blob/master/lib/rambulance/exceptions_app.rb

class ExceptionsApp < ActionController::Metal
  # In initializers `rescue_responses` is reverse_merge-ed with the default
  # responses in ActionDispatch and ActiveRecord:
  # - https://github.com/rails/rails/blob/master/actionpack/lib/action_dispatch/middleware/exception_wrapper.rb
  # - https://github.com/rails/rails/blob/master/activerecord/lib/active_record/railtie.rb
  # The responses below therefore override the Rails defaults as above.
  cattr_accessor :rescue_responses
  @@rescue_responses = Hash.new(:internal_server_error)
  @@rescue_responses.merge!(
    'ActiveRecord::RecordInvalid' => :validation_failed
  )

  delegate :response_for, to: '@response_builder'

  def initialize
    @response_builder = ResponseBuilder.new
    super
  end

  def self.call(env)
    action(:handle_exception).call(env)
  end

  def handle_exception
    exception = request.env["action_dispatch.exception"]
    method = rescue_responses[exception.class.to_s]

    response_for(method, exception)
    render(self)
  end

  def self.for(method, exception = nil)
    new.tap { |app| app.response_for(method, exception) }
  end

  def render(controller)
    controller.content_type = Mime[:json]
    controller.response_body = @response_builder.body.to_json
    controller.status = @response_builder.status
  end

  class ResponseBuilder
    attr_accessor :body
    attr_accessor :status

    def initialize
      @body = {}
      @status = nil
    end

    def response_for(method, exception = nil)
      self.body.merge! type: method
      send(method, exception)
    end

    def bad_request(*)
      self.status = 400
      self.body.merge! message: 'The request could not be understood'
    end

    def basic_authentication_incorrect(*)
      self.status = 401
      self.body.merge! message: 'The provided username/password combination is incorrect'
    end

    def token_authentication_incorrect(*)
      self.status = 401
      self.body.merge! message: 'The provided authentication token is invalid'
    end

    def token_authentication_expired(*)
      self.status = 401
      self.body.merge! message: 'The provided authentication token has expired'
    end

    def not_found(*)
      self.status = 404
      self.body.merge! message: 'Not found'
    end

    def forbidden(*)
      self.status = 403
      self.body.merge! message: 'Forbidden'
    end

    def method_not_allowed(*)
      self.status = 405
      self.body.merge! message: 'The resource was requested with a method that is not allowed'
    end

    def not_acceptable(*)
      self.status = 406
      self.body.merge! message: 'The requested resource cannot be generated with acceptable content as specified by the request headers'
    end

    def conflict(*)
      self.status = 409
      self.body.merge! message: 'The request conflicts with the current state of the server'
    end

    def unprocessable_entity(*)
      self.status = 422
      self.body.merge! message: 'The request was well-formed but contained semantic errors'
    end

    def validation_failed(exception)
      errors = exception.record.errors
      errors_json = {}

      errors.keys.each do |attribute, short_message|
        errors_json[attribute] = errors.full_messages_for(attribute)
      end

      self.status = 422
      self.body.merge! message: 'Validation failed', errors: errors_json
    end

    def internal_server_error(*)
      self.status = 500
      self.body.merge! message: 'An unexpected exception occurred on the server'
    end

    def not_implemented(*)
      self.status = 501
      self.body.merge! message: 'The resource was requested with a method that has not yet been implemented'
    end
  end
end
