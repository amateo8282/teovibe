class PortfoliosController < PostsBaseController
  private

  def category_record
    Category.find_by!(slug: "portfolio", record_type: :post)
  end
end
