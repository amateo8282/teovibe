SitemapGenerator::Sitemap.default_host = "https://teovibe.com"

SitemapGenerator::Sitemap.create do
  # 정적 페이지
  add about_path, changefreq: "monthly", priority: 0.7
  add consulting_path, changefreq: "monthly", priority: 0.6
  add rankings_path, changefreq: "daily", priority: 0.7

  # 카테고리 인덱스 (DB 기반 동적 루프 — 신규 카테고리 추가 시 자동 반영)
  Category.for_posts.ordered.each do |category|
    add category_posts_path(category_slug: category.slug), changefreq: "daily", priority: 0.8
  end

  # 스킬팩
  add skill_packs_path, changefreq: "weekly", priority: 0.8
  SkillPack.published.find_each do |skill_pack|
    add skill_pack_path(skill_pack),
      lastmod: skill_pack.updated_at,
      changefreq: "monthly",
      priority: 0.7
  end

  # 게시글 (post_path 단일 라우트 — 카테고리 무관하게 slug 기반 URL 사용)
  Post.published.find_each do |post|
    add post_path(post), lastmod: post.updated_at, changefreq: "weekly", priority: 0.8
  end
end
