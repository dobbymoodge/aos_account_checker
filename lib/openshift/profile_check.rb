require 'lib/openshift/ldap'
require 'lib/openshift/github'
require 'rack/request'
require 'erb'

class ProfileData
  attr_accessor :uid, :req, :mail, :github_id, :github_valid, :github_imperfect,
                 :trello_id, :trello_valid, :trello_imperfect,
                 :redhat_id, :redhat_valid, :redhat_imperfect

  def get_binding()
    binding()
  end
end

module OpenShift
  class ProfileCheck

    def ldap
      @ldap ||= LdapHelper.new
    end

    def github_user_check(user_name)
      user = github_user(user_name)
      login = user['login']
      name = user['name']
      email = user['email']
      valid = false
      imperfect = false
      if email && email.end_with?('@redhat.com') && ldap_user_by_email(email)
        valid = true
      else
        valid, imperfect = ldap.valid_user_name(login, name)
      end
    end

    def call(env)
      erb = ERB.new(File.open(File.expand_path("templates/form.erb"), "rb").read)
      pd = ProfileData.new
      pd.req = Rack::Request.new(env)
      pd.redhat_id = pd.req.params['redhat_id'] if pd.req.params['redhat_id']
      pd.github_id = pd.req.params['github_id'] if pd.req.params['github_id']
      pd.trello_id = pd.req.params['trello_id'] if pd.req.params['trello_id']
      pd.github_valid, pd.github_imperfect = github_user_check(pd.github_id) if pd.req.params['github_id']
      form_content = erb.result(pd.get_binding)
      [200, { "Content-Type" => "text/html" }, [ form_content ]]
    end
  end
end
