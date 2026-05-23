class CreatePointTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :point_transactions do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :amount, null: false
      t.integer :action_type, null: false
      t.references :pointable, polymorphic: true
      t.string :description

      t.timestamps
    end

    add_index :point_transactions, :action_type
  end
end
