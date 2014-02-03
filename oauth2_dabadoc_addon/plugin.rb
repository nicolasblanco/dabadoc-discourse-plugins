require 'auth/oauth2_authenticator'
require_dependency 'avatar_upload_service'

class Auth::OAuth2Authenticator
  def after_authenticate_with_auto_create(auth_token)
    result = after_authenticate_without_auto_create(auth_token)

    if !result.user
      result.user = User.create(name: result.name.strip, email: result.email, username: result.name.parameterize.gsub("-", "_"))
    end

    if result.user
      if auth_token["info"]["avatar_url"].present? && result.user.uploaded_avatar.blank?
        avatar = AvatarUploadService.new(auth_token["info"]["avatar_url"], :url)

        upload = Upload.create_for(result.user.id, avatar.file, avatar.filesize)
        result.user.upload_avatar(upload)

        Jobs.enqueue(:generate_avatars, user_id: result.user.id, upload_id: upload.id)
      end

      result.user.title, result.user.bio_raw = auth_token["info"]["title"], auth_token["info"]["bio_raw"]

      result.user.save
    end

    result
  end

  alias_method_chain :after_authenticate, :auto_create
end
