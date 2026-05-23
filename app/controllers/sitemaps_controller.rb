class SitemapsController < ApplicationController
  # 인증 불필요
  allow_unauthenticated_access

  def show
    default_url_options[:host] = request.host
    default_url_options[:protocol] = request.protocol
    @categories = Category.for_posts.ordered
    @posts = Post.published.select(:slug, :updated_at)
    @skill_packs = SkillPack.published.select(:id, :updated_at)

    respond_to do |format|
      format.xml
    end
  end
end
