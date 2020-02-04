require 'rails_helper'

RSpec.describe AuthenticationToken, type: :model do
  describe 'when creating the record' do
    it 'assigns expires_at to two weeks after created_at' do
      token = build(:authentication_token, expires_at: nil)
      token.save!

      expect(token.expires_at).to eq(token.created_at + 2.weeks)
    end

    it 'does not assign expires_at if it already has a value' do
      expires_at = 5.weeks.from_now
      token = build(:authentication_token, expires_at: expires_at)
      token.save!

      expect(token.expires_at).to eq(expires_at)
    end
  end

  specify '#expired?' do
    time = Time.zone.now
    Timecop.freeze(time) do
      expect(build_stubbed(:authentication_token, expires_at: time - 1.second)).to be_expired
      expect(build_stubbed(:authentication_token, expires_at: time)).to be_expired
      expect(build_stubbed(:authentication_token, expires_at: time + 1.second)).to_not be_expired
    end
  end

  specify '#revoked?' do
    expect(build_stubbed(:authentication_token)).to_not be_revoked
    expect(build_stubbed(:authentication_token, :revoked)).to be_revoked
  end

  specify '#revoke!' do
    token = build(:authentication_token)
    expect(token).to_not be_revoked

    time = Time.zone.now
    Timecop.freeze(time) do
      token.revoke!
      expect(token).to be_revoked
      expect(token.revoked_at).to eq time
    end

    Timecop.freeze(time + 1.day) do
      token.revoke!
      expect(token).to be_revoked
      expect(token.revoked_at).to eq time
    end
  end
end
