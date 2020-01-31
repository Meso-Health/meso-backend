UhpBackend::Application.configure do
  config.lograge.custom_options = ->(event) do
    request_id = event.payload[:headers][ActionDispatch::Request::ACTION_DISPATCH_REQUEST_ID]
    ip = event.payload[:headers]['action_dispatch.remote_ip']
    user_id = event.payload[:user_id]
    token_id = event.payload[:token_id]

    result = {
      request_id: request_id,
      ip: ip
    }
    result[:token_id] = token_id unless token_id.blank?
    result[:user_id] = user_id unless user_id.blank?

    result
  end

  config.lograge.before_format = ->(data, payload) do
    # Change log style to match Heroku's
    data[:ip] = "\"#{data[:ip]}\"" if data.has_key?(:ip)
    data[:path] = "\"#{data[:path]}\"" if data.has_key?(:path)
    data[:duration] = "#{data[:duration]}ms" if data.has_key?(:duration)
    data[:view] = "#{data[:view]}ms" if data.has_key?(:view)
    data[:db] = "#{data[:db]}ms" if data.has_key?(:db)
    data[:source] = 'app'

    sorted_data = %w[source method path request_id format controller action status duration view db].map(&:to_sym).inject({}) do |hash, key|
      hash[key] = data.delete(key)
      hash
    end
    sorted_data.merge(data)
  end
end
