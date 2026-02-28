class FreeBoardsController < PostsBaseController
  private

  def category_record
    Category.find_by!(slug: "free-board", record_type: :post)
  end
end
