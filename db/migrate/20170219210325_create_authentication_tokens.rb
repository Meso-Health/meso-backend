class CreateAuthenticationTokens < ActiveRecord::Migration[5.0]
  def change
    create_table :authentication_tokens, id: :string, limit: 8 do |t|
      t.string :secret_digest, null: false, limit: 64
      t.references :user, foreign_key: true, null: false

      t.timestamps
    end
  end
end
