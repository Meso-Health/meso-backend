class ReleaseInfo
  def initialize(env)
    @env = env
  end

  def created_at
    @created_at ||= @env.fetch('HEROKU_RELEASE_CREATED_AT', 'unknown release date')
  end

  def git_sha
    @git_sha ||= @env.fetch('HEROKU_SLUG_COMMIT') { `git rev-parse HEAD`.strip }
  end
end
