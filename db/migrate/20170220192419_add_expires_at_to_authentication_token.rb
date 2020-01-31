class AddExpiresAtToAuthenticationToken < ActiveRecord::Migration[5.0]
  def change
    add_column :authentication_tokens, :expires_at, :datetime

    AuthenticationToken.update_all("expires_at = created_at + '2 weeks'")

    change_column_null :authentication_tokens, :expires_at, false
  end
end
