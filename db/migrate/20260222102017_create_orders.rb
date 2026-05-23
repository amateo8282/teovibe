class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.references :skill_pack, null: false, foreign_key: true
      t.integer :status, default: 0, null: false      # enum: pending=0, paid=1, failed=2, refunded=3
      t.string :toss_order_id, null: false            # 우리가 생성하는 orderId
      t.string :payment_event_id                      # 토스의 paymentKey (결제 완료 후 저장)
      t.integer :amount, null: false                  # 결제 금액 (원 단위)

      t.timestamps
    end

    add_index :orders, :toss_order_id, unique: true
    add_index :orders, :payment_event_id, unique: true, where: "payment_event_id IS NOT NULL"
    add_index :orders, :status
  end
end
