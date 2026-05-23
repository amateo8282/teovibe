class CreateSkillPacks < ActiveRecord::Migration[8.1]
  def change
    create_table :skill_packs do |t|
      t.string :title, null: false
      t.text :description
      t.integer :category, default: 0, null: false
      t.string :download_token, null: false
      t.integer :downloads_count, default: 0, null: false
      t.integer :status, default: 0, null: false
      t.string :slug

      t.timestamps
    end

    add_index :skill_packs, :download_token, unique: true
    add_index :skill_packs, :slug, unique: true
    add_index :skill_packs, :category
    add_index :skill_packs, :status
  end
end
