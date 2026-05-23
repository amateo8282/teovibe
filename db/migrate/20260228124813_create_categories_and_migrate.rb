class CreateCategoriesAndMigrate < ActiveRecord::Migration[8.1]
  def up
    # 1. categories 테이블 생성
    create_table :categories do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.integer :record_type, null: false, default: 0
      t.integer :position, null: false, default: 0
      t.boolean :admin_only, null: false, default: false
      t.boolean :visible_in_nav, null: false, default: true
      t.timestamps
    end
    add_index :categories, [:slug, :record_type], unique: true

    # 2. Post 카테고리 6개 시드 (slug 기반 매핑을 위해 먼저 삽입)
    post_categories = [
      { name: "블로그", slug: "blog", position: 0, admin_only: false },
      { name: "튜토리얼", slug: "tutorial", position: 1, admin_only: false },
      { name: "자유게시판", slug: "free-board", position: 2, admin_only: false },
      { name: "Q&A", slug: "qna", position: 3, admin_only: false },
      { name: "포트폴리오", slug: "portfolio", position: 4, admin_only: false },
      { name: "공지사항", slug: "notice", position: 5, admin_only: true },
    ]
    post_categories.each do |attrs|
      execute <<~SQL
        INSERT INTO categories (name, slug, record_type, position, admin_only, visible_in_nav, created_at, updated_at)
        VALUES ('#{attrs[:name]}', '#{attrs[:slug]}', 0, #{attrs[:position]}, #{attrs[:admin_only] ? 1 : 0}, 1, datetime('now'), datetime('now'))
      SQL
    end

    # 3. SkillPack 카테고리 4개 시드
    skill_pack_categories = [
      { name: "템플릿", slug: "template", position: 0 },
      { name: "컴포넌트", slug: "component", position: 1 },
      { name: "가이드", slug: "guide", position: 2 },
      { name: "툴킷", slug: "toolkit", position: 3 },
    ]
    skill_pack_categories.each do |attrs|
      execute <<~SQL
        INSERT INTO categories (name, slug, record_type, position, admin_only, visible_in_nav, created_at, updated_at)
        VALUES ('#{attrs[:name]}', '#{attrs[:slug]}', 1, #{attrs[:position]}, 0, 1, datetime('now'), datetime('now'))
      SQL
    end

    # 4. posts 테이블에 category_id 컬럼 추가
    add_column :posts, :category_id, :integer

    # 5. 마이그레이션 전 posts 레코드 수 확인
    posts_before = execute("SELECT COUNT(*) as cnt FROM posts").first["cnt"]

    # 6. slug 기반 서브쿼리로 enum 값 → FK 매핑 (ID 기반 매핑 금지 - STATE.md 결정)
    # Post enum: { blog: 0, tutorial: 1, free_board: 2, qna: 3, portfolio: 4, notice: 5 }
    { 0 => "blog", 1 => "tutorial", 2 => "free-board", 3 => "qna", 4 => "portfolio", 5 => "notice" }.each do |enum_val, slug|
      execute <<~SQL
        UPDATE posts
        SET category_id = (SELECT id FROM categories WHERE slug = '#{slug}' AND record_type = 0)
        WHERE category = #{enum_val}
      SQL
    end

    # 7. 매핑 후 검증: category_id가 설정된 posts 수가 이전 total과 일치해야 함
    posts_mapped = execute("SELECT COUNT(*) as cnt FROM posts WHERE category_id IS NOT NULL").first["cnt"]
    if posts_before != posts_mapped
      raise "데이터 마이그레이션 실패: posts 레코드 수 불일치. 이전=#{posts_before}, 매핑=#{posts_mapped}"
    end

    # 8. posts.category enum 컬럼 제거 (SQLite 3.35+ 지원)
    remove_column :posts, :category

    # 9. skill_packs 테이블에 category_id 컬럼 추가
    add_column :skill_packs, :category_id, :integer

    # 10. 마이그레이션 전 skill_packs 레코드 수 확인
    sp_before = execute("SELECT COUNT(*) as cnt FROM skill_packs").first["cnt"]

    # 11. SkillPack enum 값 → FK 매핑
    # SkillPack enum: { template: 0, component: 1, guide: 2, toolkit: 3 }
    { 0 => "template", 1 => "component", 2 => "guide", 3 => "toolkit" }.each do |enum_val, slug|
      execute <<~SQL
        UPDATE skill_packs
        SET category_id = (SELECT id FROM categories WHERE slug = '#{slug}' AND record_type = 1)
        WHERE category = #{enum_val}
      SQL
    end

    # 12. 매핑 후 검증: category_id가 설정된 skill_packs 수가 이전 total과 일치해야 함
    sp_mapped = execute("SELECT COUNT(*) as cnt FROM skill_packs WHERE category_id IS NOT NULL").first["cnt"]
    if sp_before != sp_mapped
      raise "데이터 마이그레이션 실패: skill_packs 레코드 수 불일치. 이전=#{sp_before}, 매핑=#{sp_mapped}"
    end

    # 13. skill_packs.category enum 컬럼 제거
    remove_column :skill_packs, :category
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
