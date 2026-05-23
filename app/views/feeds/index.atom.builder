atom_feed language: "ko" do |feed|
  feed.title "TeoVibe - 바이브코딩 커뮤니티"
  feed.subtitle "바이브코딩으로 사업화하는 과정을 기록하고 공유하는 커뮤니티"
  feed.updated @posts.first&.updated_at || Time.current

  @posts.each do |post|
    feed.entry post, url: url_for_post(post), published: post.created_at, updated: post.updated_at do |entry|
      entry.title post.title
      entry.content post.body&.to_plain_text&.truncate(500), type: "text"
      entry.author do |author|
        author.name post.user.nickname
      end
      entry.category term: post.category_name
    end
  end
end
