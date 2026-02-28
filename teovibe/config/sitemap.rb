SitemapGenerator::Sitemap.default_host = "https://teovibe.com"

SitemapGenerator::Sitemap.create do
  # 정적 페이지
  add about_path, changefreq: "monthly", priority: 0.7
  add consulting_path, changefreq: "monthly", priority: 0.6
  add rankings_path, changefreq: "daily", priority: 0.7

  # 카테고리 인덱스 (Category 모델 기반 동적 루프)
  Category.for_posts.ordered.each do |category|
    slug = category.slug
    # 기존 라우트 유지 (SEO URL 파괴 금지)
    path = case slug
           when "blog" then blogs_path
           when "tutorial" then tutorials_path
           when "free-board" then free_boards_path
           when "qna" then qnas_path
           when "portfolio" then portfolios_path
           when "notice" then notices_path
           end
    add path, changefreq: "daily", priority: 0.8 if path
  end

  # 스킬팩
  add skill_packs_path, changefreq: "weekly", priority: 0.8
  SkillPack.published.find_each do |skill_pack|
    add skill_pack_path(skill_pack),
      lastmod: skill_pack.updated_at,
      changefreq: "monthly",
      priority: 0.7
  end

  # 게시글 (category.slug 기반 라우트)
  Post.published.find_each do |post|
    slug = post.category&.slug
    next unless slug
    path = case slug
           when "blog" then blog_path(post)
           when "tutorial" then tutorial_path(post)
           when "free-board" then free_board_path(post)
           when "qna" then qna_path(post)
           when "portfolio" then portfolio_path(post)
           when "notice" then notice_path(post)
           end
    add path, lastmod: post.updated_at, changefreq: "weekly", priority: 0.8 if path
  end
end
