class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :actor_id
      t.references :notifiable, polymorphic: true
      t.integer :notification_type, null: false, default: 0
      t.boolean :read, null: false, default: false
      t.datetime :read_at

      t.timestamps
    end

    add_index :notifications, [:user_id, :read]
    add_foreign_key :notifications, :users, column: :actor_id
  end
end
