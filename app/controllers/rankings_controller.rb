class RankingsController < ApplicationController
  allow_unauthenticated_access

  def index
    @users = User.where("points > 0").order(points: :desc, level: :desc).limit(50)
  end
end
