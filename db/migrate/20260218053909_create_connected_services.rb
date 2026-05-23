class CreateConnectedServices < ActiveRecord::Migration[8.1]
  def change
    create_table :connected_services do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider
      t.string :uid
      t.string :access_token

      t.timestamps
    end
  end
end
