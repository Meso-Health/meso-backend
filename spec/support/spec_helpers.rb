module SpecHelpers
  def dragonfly_url_process_steps(url)
    base64_job = url.split('/').last.split('-').first
    job = Dragonfly::Job.deserialize(base64_job, Dragonfly.app)
    job.process_steps
  end
end

RSpec.configure do |config|
  config.include SpecHelpers
end
