class TutorialsController < PostsBaseController
  private

  def category_record
    Category.find_by!(slug: "tutorial", record_type: :post)
  end
end
