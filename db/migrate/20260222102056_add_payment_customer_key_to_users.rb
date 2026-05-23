class AddPaymentCustomerKeyToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :payment_customer_key, :string
  end
end
