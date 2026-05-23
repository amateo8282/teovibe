class CreateInquiries < ActiveRecord::Migration[8.1]
  def change
    create_table :inquiries do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :phone
      t.string :company
      t.string :subject, null: false
      t.text :body, null: false
      t.integer :status, default: 0, null: false
      t.text :admin_reply
      t.datetime :replied_at

      t.timestamps
    end

    add_index :inquiries, :status
  end
end
