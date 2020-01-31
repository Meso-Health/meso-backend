require 'rails_helper'

RSpec.describe "Error handling", type: :request do
  describe "when route not found" do
    it 'GET returns 404 page with a JSON response' do
      get '/does_not_exist', as: :json

      expect(response).to be_not_found
      expect(json['type']).to eq 'not_found'
      expect(json['message']).to eq 'Not found'
    end

    it 'GET a non-existent record returns 404 page with a JSON response' do
      get '/providers/1', as: :json

      expect(response).to be_not_found
      expect(json['type']).to eq 'not_found'
      expect(json['message']).to eq 'Not found'
    end

    it 'POST returns 404 page with a JSON response' do
      post '/does_not_exist', as: :json

      expect(response).to be_not_found
      expect(json['type']).to eq 'not_found'
      expect(json['message']).to eq 'Not found'
    end
  end

  describe "when there's a validation error" do
    it 'POST returns a 422 page with a JSON response' do
      member = create(:member)
      patch member_url(member), params: {gender: 'invalid'}, headers: token_auth_header, as: :json

      expect(response.status).to eq 422
      expect(json['type']).to eq 'validation_failed'
      expect(json['message']).to eq 'Validation failed'
      expect(json['errors'].size).to eq 1
      expect(json['errors']['gender'].size).to eq 1
    end
  end
end
