class NoticesController < PostsBaseController
  private

  def category_record
    Category.find_by!(slug: "notice", record_type: :post)
  end
end
