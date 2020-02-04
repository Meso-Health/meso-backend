class AddRevokedAtToAuthenticationToken < ActiveRecord::Migration[5.0]
  def change
    add_column :authentication_tokens, :revoked_at, :timestamp
  end
end
