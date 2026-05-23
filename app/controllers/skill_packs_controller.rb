class SkillPacksController < ApplicationController
  allow_unauthenticated_access only: [:index, :show, :token_download]

  def index
    @skill_packs = SkillPack.published
    @skill_packs = @skill_packs.by_category(params[:category]) if params[:category].present?
    @skill_packs = @skill_packs.order(created_at: :desc)
    @pagy, @skill_packs = pagy(:offset, @skill_packs, limit: 12)
  end

  def show
    @skill_pack = SkillPack.published.find(params[:id])
  end

  def download
    @skill_pack = SkillPack.published.find(params[:id])

    unless Current.user
      session[:return_to_after_authenticating] = download_skill_pack_path(@skill_pack)
      redirect_to new_session_path, alert: "다운로드하려면 로그인이 필요합니다."
      return
    end

    record_download(@skill_pack)
    redirect_to rails_blob_path(@skill_pack.file, disposition: "attachment")
  end

  def token_download
    @skill_pack = SkillPack.published.find_by!(download_token: params[:download_token])

    unless Current.user
      session[:return_to_after_authenticating] = token_download_path(@skill_pack.download_token)
      redirect_to new_session_path, alert: "다운로드하려면 로그인이 필요합니다."
      return
    end

    record_download(@skill_pack)
    redirect_to rails_blob_path(@skill_pack.file, disposition: "attachment")
  end

  private

  def record_download(skill_pack)
    skill_pack.downloads.find_or_create_by(user: Current.user) do |dl|
      dl.ip_address = request.remote_ip
    end
  end
end
