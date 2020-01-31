class StatusController < ActionController::Metal
  def index
    response = {
      released_at: UhpBackend.release.created_at,
      release_commit_sha: UhpBackend.release.git_sha
    }

    self.content_type = Mime[:json]
    self.response_body = response.to_json
  end
end
