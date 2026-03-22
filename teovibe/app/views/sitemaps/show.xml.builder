xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  # 홈
  xml.url do
    xml.loc root_url
    xml.changefreq "daily"
    xml.priority "1.0"
  end

  # 정적 페이지
  xml.url do
    xml.loc about_url
    xml.changefreq "monthly"
    xml.priority "0.7"
  end

  xml.url do
    xml.loc consulting_url
    xml.changefreq "monthly"
    xml.priority "0.6"
  end

  xml.url do
    xml.loc rankings_url
    xml.changefreq "daily"
    xml.priority "0.7"
  end

  # 카테고리별 게시글 목록
  @categories.each do |category|
    xml.url do
      xml.loc category_posts_url(category_slug: category.slug)
      xml.changefreq "daily"
      xml.priority "0.8"
    end
  end

  # 스킬팩 목록
  xml.url do
    xml.loc skill_packs_url
    xml.changefreq "weekly"
    xml.priority "0.8"
  end

  # 개별 스킬팩
  @skill_packs.each do |skill_pack|
    xml.url do
      xml.loc skill_pack_url(skill_pack)
      xml.lastmod skill_pack.updated_at.strftime("%Y-%m-%d")
      xml.changefreq "monthly"
      xml.priority "0.7"
    end
  end

  # 게시글
  @posts.each do |post|
    xml.url do
      xml.loc post_url(post)
      xml.lastmod post.updated_at.strftime("%Y-%m-%d")
      xml.changefreq "weekly"
      xml.priority "0.8"
    end
  end
end
