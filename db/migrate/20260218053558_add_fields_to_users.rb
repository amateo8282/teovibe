class AddFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :nickname, :string, null: false, default: ""
    add_column :users, :avatar_url, :string
    add_column :users, :bio, :text
    add_column :users, :role, :integer, default: 0, null: false
    add_column :users, :points, :integer, default: 0, null: false
    add_column :users, :level, :integer, default: 1, null: false
    add_column :users, :posts_count, :integer, default: 0, null: false
    add_column :users, :comments_count, :integer, default: 0, null: false
  end
end
