class AddSocialLinksToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :github_url, :string
    add_column :users, :twitter_url, :string
    add_column :users, :website_url, :string
  end
end
