class AddPriceToSkillPacks < ActiveRecord::Migration[8.1]
  def change
    # price = 0이면 무료, 0 초과이면 유료 (원 단위)
    add_column :skill_packs, :price, :integer, default: 0, null: false
  end
end
