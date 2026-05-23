class CreateLandingSections < ActiveRecord::Migration[8.1]
  def change
    create_table :landing_sections do |t|
      t.integer :section_type, default: 0, null: false
      t.string :title, null: false
      t.text :subtitle
      t.integer :position, default: 0, null: false
      t.boolean :active, default: true, null: false
      t.string :background_color
      t.string :text_color

      t.timestamps
    end
    add_index :landing_sections, :position
  end
end
