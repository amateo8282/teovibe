class PointService
  # 활동별 포인트 설정
  POINTS = {
    post_created: 10,
    comment_created: 3,
    liked_received: 2,
    download_skill_pack: 1,
    daily_login: 1,
    level_up_bonus: 20
  }.freeze

  # 레벨별 필요 포인트 (Lv1=0, Lv2=50, ...)
  LEVEL_THRESHOLDS = {
    1 => 0,
    2 => 50,
    3 => 150,
    4 => 300,
    5 => 500,
    6 => 800,
    7 => 1200,
    8 => 1800,
    9 => 2500,
    10 => 3500
  }.freeze

  def self.award(action_type, user:, pointable: nil, description: nil)
    new.award(action_type, user: user, pointable: pointable, description: description)
  end

  def award(action_type, user:, pointable: nil, description: nil)
    amount = POINTS[action_type.to_sym]
    return unless amount

    desc = description || default_description(action_type)

    PointTransaction.create!(
      user: user,
      amount: amount,
      action_type: action_type,
      pointable: pointable,
      description: desc
    )

    user.increment!(:points, amount)
    check_level_up(user)
  end

  # 일일 로그인 포인트 (당일 첫 로그인만)
  def self.award_daily_login(user)
    return if PointTransaction.where(user: user, action_type: :daily_login)
                              .where("created_at >= ?", Time.current.beginning_of_day)
                              .exists?

    new.award(:daily_login, user: user, description: "일일 로그인 보너스")
  end

  private

  def check_level_up(user)
    new_level = calculate_level(user.points)
    if new_level > user.level
      user.update!(level: new_level)
      PointTransaction.create!(
        user: user,
        amount: POINTS[:level_up_bonus],
        action_type: :level_up_bonus,
        description: "레벨 #{new_level} 달성 보너스"
      )
      user.increment!(:points, POINTS[:level_up_bonus])
      NotificationService.level_up(user)
    end
  end

  def calculate_level(points)
    LEVEL_THRESHOLDS.select { |_, threshold| points >= threshold }.keys.max || 1
  end

  def default_description(action_type)
    {
      post_created: "글 작성",
      comment_created: "댓글 작성",
      liked_received: "좋아요 받음",
      download_skill_pack: "스킬팩 다운로드",
      daily_login: "일일 로그인",
      level_up_bonus: "레벨업 보너스"
    }[action_type.to_sym]
  end
end
