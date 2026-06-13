class CreateCourses < ActiveRecord::Migration[8.1]
  def change
    create_table :courses do |t|
      t.string  :title, null: false
      t.string  :slug, null: false
      t.text    :description
      t.string  :emoji
      t.string  :deck_file, null: false          # 슬라이드 HTML 파일명 (app/decks/)
      t.boolean :paid, null: false, default: false
      t.integer :price, null: false, default: 0  # KRW
      t.string  :polar_product_id
      t.string  :polar_benefit_id
      t.string  :checkout_url
      t.integer :slides_count
      t.string  :duration
      t.string  :tag                              # 배지 텍스트 (예: WEEK 1-2)
      t.string  :level                            # 기본 / 심화
      t.string  :thumb_style, default: "thumb--dark"
      t.integer :position, null: false, default: 0
      t.integer :status, null: false, default: 1  # 0 draft / 1 published
      t.timestamps
    end
    add_index :courses, :slug, unique: true
    add_index :courses, :polar_benefit_id
    add_index :courses, :position
  end
end
