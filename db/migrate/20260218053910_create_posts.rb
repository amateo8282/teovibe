class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.string :slug
      t.integer :category, default: 0, null: false
      t.integer :status, default: 0, null: false
      t.text :body
      t.boolean :pinned, default: false, null: false
      t.string :seo_title
      t.text :seo_description
      t.integer :views_count, default: 0, null: false
      t.integer :likes_count, default: 0, null: false
      t.integer :comments_count, default: 0, null: false

      t.timestamps
    end
    add_index :posts, :slug, unique: true
    add_index :posts, :category
    add_index :posts, :status
  end
end
