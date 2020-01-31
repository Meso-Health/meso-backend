class AuthenticationService
  def create_token!(user)
    id = generate_unique_id
    secret = generate_random_secret
    secret_digest = digest_secret(secret)

    object = AuthenticationToken.create!(id: id, secret_digest: secret_digest, user: user)

    return encode_combined_token(id, secret), object
  end

  def verify_token(combined_token)
    id, secret = decode_combined_token(combined_token)
    token = AuthenticationToken.find_by(id: id)

    return nil unless token.present?
    return nil unless ActiveSupport::SecurityUtils.secure_compare(token.secret_digest, digest_secret(secret))
    return nil if token.expired?
    return nil if token.revoked?

    token
  end

  def token_expired?(combined_token)
    id, secret = decode_combined_token(combined_token)
    token = AuthenticationToken.find_by(id: id)

    return false unless token.present?
    return false unless ActiveSupport::SecurityUtils.secure_compare(token.secret_digest, digest_secret(secret))
    return false if token.revoked?

    token.expired?
  end

  private
  def encode_combined_token(id, secret)
    [id, secret].join('.')
  end

  def decode_combined_token(combined_token)
    combined_token.split('.')[0..1]
  end

  def generate_unique_id
    loop do
      id = generate_random_id
      return id unless AuthenticationToken.where(id: id).exists?
    end
  end

  def generate_random_id
    SecureRandom.base58(8)
  end

  def generate_random_secret
    SecureRandom.base58(32)
  end

  def digest_secret(secret)
    ::Digest::SHA256.hexdigest(secret)
  end
end
