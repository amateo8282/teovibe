class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.string  :payment_id, null: false           # 포트원 paymentId (멱등키)
      t.string  :provider, null: false, default: "portone"
      t.integer :amount, null: false               # KRW
      t.integer :status, null: false, default: 0   # 0 pending / 1 paid / 2 failed / 3 cancelled
      t.timestamps
    end
    add_index :payments, :payment_id, unique: true
  end
end
