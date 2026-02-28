require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  fixtures :categories

  # 유효성 검증 테스트
  test "name이 없으면 유효하지 않다" do
    category = Category.new(slug: "test", record_type: :post)
    assert_not category.valid?
    assert_includes category.errors[:name], "can't be blank"
  end

  test "slug가 없으면 유효하지 않다" do
    category = Category.new(name: "테스트", record_type: :post)
    assert_not category.valid?
    assert_includes category.errors[:slug], "can't be blank"
  end

  test "같은 record_type 내에서 slug는 유니크해야 한다" do
    existing = categories(:blog)
    duplicate = Category.new(name: "블로그2", slug: existing.slug, record_type: existing.record_type)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:slug], "has already been taken"
  end

  test "다른 record_type에서는 같은 slug를 사용할 수 있다" do
    # blog slug는 record_type=0(post)에서 사용 중이지만, record_type=1(skill_pack)에서는 가능
    category = Category.new(name: "블로그팩", slug: "blog", record_type: :skill_pack)
    assert category.valid?
  end

  # 스코프 테스트
  test "for_posts 스코프는 record_type=post인 카테고리만 반환한다" do
    post_cats = Category.for_posts
    assert post_cats.all? { |c| c.post? }, "for_posts에 skill_pack 카테고리가 포함됨"
    assert_includes post_cats.map(&:slug), "blog"
  end

  test "for_skill_packs 스코프는 record_type=skill_pack인 카테고리만 반환한다" do
    sp_cats = Category.for_skill_packs
    assert sp_cats.all? { |c| c.skill_pack? }, "for_skill_packs에 post 카테고리가 포함됨"
    assert_includes sp_cats.map(&:slug), "template"
  end

  test "ordered 스코프는 position 오름차순으로 정렬한다" do
    post_cats = Category.for_posts.ordered
    positions = post_cats.map(&:position)
    assert_equal positions.sort, positions, "ordered 스코프가 position 오름차순이 아님"
  end

  test "visible_in_nav 스코프는 visible_in_nav=true인 카테고리만 반환한다" do
    visible = Category.visible_in_nav
    assert visible.all?(&:visible_in_nav?), "visible_in_nav에 hidden 카테고리가 포함됨"
    assert_not_includes visible.map(&:slug), "component"  # component는 visible_in_nav: false
  end

  # 삭제 보호 테스트
  test "게시글이 없는 카테고리는 삭제할 수 있다" do
    category = Category.create!(name: "삭제테스트", slug: "delete-test-#{SecureRandom.hex(4)}", record_type: :post)
    assert category.destroy, "게시글이 없는 카테고리 삭제 실패"
  end

  test "게시글이 있는 카테고리는 삭제를 거부한다" do
    category = categories(:blog)
    # blog 카테고리에 post가 있으면 삭제 거부 테스트
    # 테스트 환경에서 posts가 없으므로 직접 생성
    user = User.create!(
      email_address: "test-cat-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      nickname: "테스터"
    )
    post = Post.create!(title: "테스트 글", category: category, user: user, status: :published)

    assert_not category.destroy, "게시글이 있는 카테고리가 삭제되었음"
    assert_includes category.errors[:base].join, "삭제할 수 없습니다"

    post.destroy
    user.destroy
  end

  # move_up / move_down 테스트
  test "move_up은 같은 record_type 내에서 position을 교환한다" do
    cat1 = categories(:blog)     # position 0
    cat2 = categories(:tutorial) # position 1

    cat2.move_up

    cat1.reload
    cat2.reload

    assert_equal 0, cat2.position, "move_up 후 cat2의 position이 0이어야 함"
    assert_equal 1, cat1.position, "move_up 후 cat1의 position이 1이어야 함"

    # 원래 상태로 복원
    cat1.update!(position: 0)
    cat2.update!(position: 1)
  end

  test "move_down은 같은 record_type 내에서 position을 교환한다" do
    cat1 = categories(:blog)     # position 0
    cat2 = categories(:tutorial) # position 1

    cat1.move_down

    cat1.reload
    cat2.reload

    assert_equal 1, cat1.position, "move_down 후 cat1의 position이 1이어야 함"
    assert_equal 0, cat2.position, "move_down 후 cat2의 position이 0이어야 함"

    # 원래 상태로 복원
    cat1.update!(position: 0)
    cat2.update!(position: 1)
  end

  test "move_up은 가장 위에 있는 카테고리에서 아무것도 하지 않는다" do
    cat = categories(:blog) # position 0 (최상단)
    original_position = cat.position
    cat.move_up
    cat.reload
    assert_equal original_position, cat.position, "최상단 카테고리의 position이 변경됨"
  end
end
