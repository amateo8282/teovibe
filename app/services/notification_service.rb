class NotificationService
  def self.notify(user:, actor:, notifiable:, notification_type:)
    return if user == actor # 본인에게는 알림 보내지 않음

    Notification.create!(
      user: user,
      actor: actor,
      notifiable: notifiable,
      notification_type: notification_type
    )
  end

  # 댓글 -> 글 작성자에게 알림
  def self.comment_created(comment)
    post_author = comment.post.user
    notify(
      user: post_author,
      actor: comment.user,
      notifiable: comment,
      notification_type: :new_comment
    )
  end

  # 대댓글 -> 부모 댓글 작성자에게 알림
  def self.comment_replied(comment)
    return unless comment.parent

    parent_author = comment.parent.user
    notify(
      user: parent_author,
      actor: comment.user,
      notifiable: comment,
      notification_type: :comment_reply
    )
  end

  # 좋아요 -> 대상 콘텐츠 작성자에게 알림
  def self.liked(like)
    author = like.likeable.user
    type = like.likeable_type == "Post" ? :post_liked : :comment_liked
    notify(
      user: author,
      actor: like.user,
      notifiable: like,
      notification_type: type
    )
  end

  # 레벨업 -> 본인에게 알림
  def self.level_up(user)
    Notification.create!(
      user: user,
      actor: user,
      notifiable: user,
      notification_type: :level_up
    )
  end
end
