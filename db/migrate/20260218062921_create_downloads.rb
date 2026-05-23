class CreateDownloads < ActiveRecord::Migration[8.1]
  def change
    create_table :downloads do |t|
      t.references :user, null: false, foreign_key: true
      t.references :skill_pack, null: false, foreign_key: true
      t.string :ip_address

      t.timestamps
    end
  end
end
