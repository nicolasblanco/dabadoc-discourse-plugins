require 'auth/oauth2_authenticator'
require 'omniauth-oauth2'

class OmniAuth::Strategies::DabadocOauth < OmniAuth::Strategies::OAuth2

  # NOTE VM has to be able to resolve
  SITE_URL = GlobalSetting.dabadoc_oauth_site_url

  # Give your strategy a name.
  option :name, "dabadoc_oauth"

  # This is where you pass the options you would pass when
  # initializing your consumer from the OAuth gem.
  option :client_options, site: SITE_URL

  # These are called after authentication has succeeded. If
  # possible, you should try to set the UID without making
  # additional calls (if the user id is returned with the token
  # or as a URI parameter). This may not be possible with all
  # providers.
  uid { raw_info['id'] }

  info do
    {
      name: raw_info['name'],
      email: raw_info['email'],
      avatar_url: raw_info['avatar_url'],
      title: raw_info['title'],
      bio_raw: raw_info['bio_raw']
    }
  end

  extra do
    {
      'raw_info' => raw_info
    }
  end

  def raw_info
    @raw_info ||= access_token.get('/api/v1/users/me.json').parsed
  end
end

class DabadocAuthenticator < ::Auth::OAuth2Authenticator

  CLIENT_ID = GlobalSetting.dabadoc_oauth_client_id
  CLIENT_SECRET = GlobalSetting.dabadoc_oauth_client_secret

  def register_middleware(omniauth)
    omniauth.provider :dabadoc_oauth,
      CLIENT_ID,
      CLIENT_SECRET
  end
end

auth_provider(title: 'Connexion via DabaDoc',
    message: 'Connexion via Dabadoc (désactivez votre anti-popup en cas de problème).',
    frame_width: 920,
    frame_height: 800,
    authenticator: DabadocAuthenticator.new('dabadoc_oauth', trusted: true))


register_css <<CSS

.btn-social.dabadoc_oauth {
  background: #4881CD;
}

CSS
