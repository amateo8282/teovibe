class CreateSectionCards < ActiveRecord::Migration[8.1]
  def change
    create_table :section_cards do |t|
      t.references :landing_section, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.string :icon
      t.string :link_url
      t.string :link_text
      t.integer :position

      t.timestamps
    end
  end
end
