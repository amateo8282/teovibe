module Api
  module V1
    class PostsController < ApplicationController
      include ApiAuthentication
      skip_before_action :verify_authenticity_token
      allow_unauthenticated_access

      def create
        category = Category.find_by(slug: params.dig(:post, :category_slug)) ||
                   Category.find_by(slug: "blog")

        @post = current_api_user.posts.build(
          title: params.dig(:post, :title),
          category: category,
          status: :draft,
          seo_title: params.dig(:post, :seo_title),
          seo_description: params.dig(:post, :seo_description)
        )
        @post.body = MarkdownRenderer.render(params.dig(:post, :body))

        if @post.save
          render json: {
            id: @post.id,
            slug: @post.slug,
            title: @post.title,
            status: @post.status,
            url: "https://jaeho.im/posts/#{@post.slug}"
          }, status: :created
        else
          render json: { errors: @post.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end
end
