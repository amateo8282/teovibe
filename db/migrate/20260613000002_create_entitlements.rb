class CreateEntitlements < ActiveRecord::Migration[8.1]
  def change
    create_table :entitlements do |t|
      t.references :user, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.integer  :source, null: false, default: 0   # 0 purchase / 1 license_key / 2 grant / 3 manual
      t.integer  :status, null: false, default: 0    # 0 active / 1 revoked
      t.string   :polar_order_id
      t.string   :license_key
      t.datetime :revoked_at
      t.timestamps
    end
    add_index :entitlements, %i[user_id course_id], unique: true
    add_index :entitlements, :polar_order_id
  end
end
