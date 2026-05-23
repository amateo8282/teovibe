require "test_helper"

# CATM-01~06 Admin 카테고리 컨트롤러 통합 테스트
class Admin::CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @member = users(:one)
    @blog_category = categories(:blog)
    @notice_category = categories(:notice)
    @template_category = categories(:template)
  end

  # ========== 인증 가드 ==========

  test "비인증 사용자는 카테고리 목록에 접근 불가 (로그인 페이지로 리다이렉트)" do
    get admin_categories_path
    assert_redirected_to new_session_path
  end

  test "일반 회원은 Admin 카테고리 목록에 접근 불가" do
    sign_in_as(@member)
    get admin_categories_path
    assert_redirected_to root_path
  end

  # ========== CATM-01: 카테고리 생성 ==========

  test "Admin이 게시판 카테고리를 생성하면 목록에 추가된다" do
    sign_in_as(@admin)
    assert_difference("Category.count", 1) do
      post admin_categories_path, params: {
        category: {
          name: "새 카테고리",
          slug: "new-category",
          description: "테스트 카테고리",
          record_type: "post"
        }
      }
    end
    assert_redirected_to admin_categories_path
    assert_equal "새 카테고리", Category.last.name
    assert_equal "post", Category.last.record_type
  end

  test "Admin이 스킬팩 카테고리를 생성한다 (CATM-06)" do
    sign_in_as(@admin)
    assert_difference("Category.count", 1) do
      post admin_categories_path, params: {
        category: {
          name: "새 스킬팩 카테고리",
          slug: "new-skillpack-category",
          record_type: "skill_pack"
        }
      }
    end
    assert_redirected_to admin_categories_path
    assert_equal "skill_pack", Category.last.record_type
  end

  test "Admin이 필수값 없이 카테고리 생성 시도하면 실패한다" do
    sign_in_as(@admin)
    assert_no_difference("Category.count") do
      post admin_categories_path, params: {
        category: { name: "", slug: "", record_type: "post" }
      }
    end
    assert_response :unprocessable_entity
  end

  # ========== CATM-02: 카테고리 수정 ==========

  test "Admin이 카테고리 이름/설명을 수정한다" do
    sign_in_as(@admin)
    patch admin_category_path(@blog_category), params: {
      category: { name: "블로그 수정됨", description: "수정된 설명" }
    }
    assert_redirected_to admin_categories_path
    @blog_category.reload
    assert_equal "블로그 수정됨", @blog_category.name
    assert_equal "수정된 설명", @blog_category.description
  end

  test "Admin이 게시글 없는 카테고리를 삭제한다" do
    sign_in_as(@admin)
    # 게시글 없는 카테고리 사용 (tutorial)
    tutorial = categories(:tutorial)
    assert_difference("Category.count", -1) do
      delete admin_category_path(tutorial)
    end
    assert_redirected_to admin_categories_path
    assert_includes flash[:notice], "삭제"
  end

  test "Admin이 게시글 있는 카테고리 삭제 시도 시 거부된다" do
    sign_in_as(@admin)
    # blog 카테고리에는 blog_post 픽스처가 있음
    assert_no_difference("Category.count") do
      delete admin_category_path(@blog_category)
    end
    assert_redirected_to admin_categories_path
    assert_not_nil flash[:alert]
  end

  # ========== CATM-03: 순서 변경 ==========

  test "Admin이 reorder 엔드포인트로 카테고리 position을 업데이트한다" do
    sign_in_as(@admin)
    tutorial = categories(:tutorial)
    notice = categories(:notice)

    # blog=1위, tutorial=2위, notice=3위 순서로 재정렬
    patch reorder_admin_categories_path, params: {
      positions: [ @blog_category.id, tutorial.id, notice.id ]
    }
    assert_response :ok
    @blog_category.reload
    tutorial.reload
    notice.reload

    assert_equal 1, @blog_category.position
    assert_equal 2, tutorial.position
    assert_equal 3, notice.position
  end

  # ========== CATM-04: admin_only 토글 ==========

  test "Admin이 toggle_admin_only로 admin_only 속성을 반전시킨다" do
    sign_in_as(@admin)
    original = @blog_category.admin_only

    patch toggle_admin_only_admin_category_path(@blog_category)
    @blog_category.reload

    assert_equal !original, @blog_category.admin_only
  end

  test "toggle_admin_only는 turbo_stream 또는 HTML 응답을 반환한다" do
    sign_in_as(@admin)
    patch toggle_admin_only_admin_category_path(@blog_category)
    # HTML 폴백: admin_categories_path 리다이렉트
    assert_redirected_to admin_categories_path
  end

  # ========== visible_in_nav 토글 ==========

  test "Admin이 toggle_visible_in_nav로 visible_in_nav 속성을 반전시킨다" do
    sign_in_as(@admin)
    original = @blog_category.visible_in_nav

    patch toggle_visible_in_nav_admin_category_path(@blog_category)
    @blog_category.reload

    assert_equal !original, @blog_category.visible_in_nav
  end

  # ========== CATM-06: 스킬팩 카테고리 CRUD ==========

  test "Admin이 스킬팩 카테고리를 수정한다" do
    sign_in_as(@admin)
    patch admin_category_path(@template_category), params: {
      category: { name: "템플릿 수정됨" }
    }
    assert_redirected_to admin_categories_path
    @template_category.reload
    assert_equal "템플릿 수정됨", @template_category.name
  end

  test "Admin이 스킬팩 카테고리를 삭제한다 (스킬팩 없는 경우)" do
    sign_in_as(@admin)
    # component 카테고리: skill_packs 픽스처가 참조하므로 게시물 있는 카테고리
    # template 카테고리는 픽스처에서 skill_packs.one이 참조 — 있는 경우
    # 새로 만들어서 테스트
    empty_category = Category.create!(
      name: "빈 스킬팩 카테고리", slug: "empty-skillpack", record_type: :skill_pack, position: 99
    )
    assert_difference("Category.count", -1) do
      delete admin_category_path(empty_category)
    end
    assert_redirected_to admin_categories_path
  end
end
