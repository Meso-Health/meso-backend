require 'rails_helper'

RSpec.describe ApplicationWorker, type: :worker do
  describe "#before_perform" do
    it 'sets PaperTrail source to the worker class name' do
      ApplicationWorker.new.before_perform

      expect(PaperTrail.request.controller_info[:source]).to eq 'ApplicationWorker'
    end

    it 'sets the PaperTrail release commit sha to the current release' do
      git_sha = 'current-release-sha'
      expect(UhpBackend.release).to receive(:git_sha).and_return(git_sha)

      ApplicationWorker.new.before_perform

      expect(PaperTrail.request.controller_info[:release_commit_sha]).to eq git_sha
    end
  end
end
