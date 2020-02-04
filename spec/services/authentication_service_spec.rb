require 'rails_helper'

RSpec.describe AuthenticationService do
  describe '#create_token!' do
    let(:user) { create(:user) }

    it 'returns a combined token in the expected format' do
      combined_token, = subject.create_token!(user)
      expect(combined_token).to match /^\w{8}.\w{32}$/
    end

    it 'generates a unique id per token' do
      existing_id = subject.create_token!(user).split('.').first
      new_id = 'abcdefgh'
      expect(subject).to receive(:generate_random_id).and_return(existing_id, new_id)

      combined_token, = subject.create_token!(user)
      expect(combined_token).to start_with new_id
    end

    it 'saves an AuthenticationToken object' do
      combined_token, object = subject.create_token!(user)
      id, secret = combined_token.split('.')

      expect(object.id).to eq id
      expect(object.secret_digest).to_not eq secret
      expect(object.user).to eq user
    end
  end

  describe '#verify_token' do
    it 'returns nil for an invalid combined token' do
      expect(subject.verify_token('a.b.c')).to be_nil
    end

    it 'returns nil for a non-existent token id' do
      expect(subject.verify_token('abcdefgh.asdf')).to be_nil
    end

    it 'returns nil for an incorrect token secret' do
      user = create(:user)
      combined_token, = subject.create_token!(user)
      id, secret = combined_token.split('.')

      expect(subject.verify_token("#{id}.asdf")).to be_nil
    end

    it 'returns nil for an expired token' do
      user = create(:user)
      combined_token, object = subject.create_token!(user)
      object.update!(expires_at: 1.day.ago)

      expect(subject.verify_token(combined_token)).to be_nil
    end

    it 'returns nil for a revoked token' do
      user = create(:user)
      combined_token, object = subject.create_token!(user)
      object.revoke!

      expect(subject.verify_token(combined_token)).to be_nil
    end

    it 'returns the token for a valid combined token' do
      user = create(:user)
      combined_token, object = subject.create_token!(user)

      expect(subject.verify_token(combined_token)).to eq object
    end
  end

  describe '#token_expired?' do
    it 'returns false for an invalid combined token' do
      expect(subject.token_expired?('a.b.c')).to be false
    end

    it 'returns false for a non-existent token id' do
      expect(subject.token_expired?('abcdefgh.asdf')).to be false
    end

    it 'returns false for an incorrect token secret' do
      user = create(:user)
      combined_token, = subject.create_token!(user)
      id, secret = combined_token.split('.')

      expect(subject.token_expired?("#{id}.asdf")).to be false
    end

    it 'returns true for an expired token' do
      user = create(:user)
      combined_token, object = subject.create_token!(user)
      object.update!(expires_at: 1.day.ago)

      expect(subject.token_expired?(combined_token)).to be true
    end

    it 'returns false for a revoked token' do
      user = create(:user)
      combined_token, object = subject.create_token!(user)
      object.revoke!

      expect(subject.token_expired?(combined_token)).to be false
    end

    it 'returns false for a valid combined token' do
      user = create(:user)
      combined_token, object = subject.create_token!(user)

      expect(subject.token_expired?(combined_token)).to be false
    end
  end
end
