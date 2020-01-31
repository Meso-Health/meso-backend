class ApplicationWorker
  def before_perform(*args)
    PaperTrail.request.controller_info = {
      source: self.class.to_s,
      release_commit_sha: UhpBackend.release.git_sha
    }
  end
end
