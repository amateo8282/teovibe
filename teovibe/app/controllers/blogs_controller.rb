class BlogsController < PostsBaseController
  private

  def category_record
    Category.find_by!(slug: "blog", record_type: :post)
  end
end
