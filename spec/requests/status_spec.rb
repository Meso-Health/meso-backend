require 'rails_helper'

RSpec.describe "Status", type: :request do
  describe "GET /status" do
    it "returns 200" do
      get status_url
      expect(response).to be_successful
    end

    it "returns the current release info" do
      created_at = '2015-04-02T18:00:42Z'
      git_sha = '2f458bd49e765c73c7764467f6918422ebc5b759'
      expect(UhpBackend.release).to receive(:created_at).and_return(created_at)
      expect(UhpBackend.release).to receive(:git_sha).and_return(git_sha)

      get status_url

      expect(json['released_at']).to eq created_at
      expect(json['release_commit_sha']).to eq git_sha
    end
  end

  describe "GET /" do
    it 'routes to the status page' do
      get root_url

      expect(response).to be_successful
      expect(json.keys).to match_array(%w[released_at release_commit_sha])
    end
  end
end
