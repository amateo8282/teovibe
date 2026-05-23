class AddSchedulingToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :scheduled_at, :datetime
    add_column :posts, :job_id, :string
    # 예약 발행 게시글 조회 성능을 위한 인덱스
    add_index :posts, :scheduled_at
  end
end
