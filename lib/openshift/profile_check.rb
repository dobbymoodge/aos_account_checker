require 'lib/openshift/ldap'
require 'rack/request'
require 'erb'

class ProfileData
  attr_accessor :uid, :req, :mail
  def get_binding()
    binding()
  end
end

module OpenShift
  class ProfileCheck
    def call(env)
      erb = ERB.new(File.open(File.expand_path("templates/form.erb"), "rb").read)
      pd = ProfileData.new
      pd.req = Rack::Request.new(env)
      uid = pd.req.params['redhat_id'] ? pd.req.params['redhat_id'] : 'jolamb'
      user = ldap_user_by_uid(uid)
      pd.uid = user.dn
      pd.mail = user.mail
      form_content = erb.result(pd.get_binding)
      [200, { "Content-Type" => "text/html" }, [ form_content ]]
    end
  end
end
