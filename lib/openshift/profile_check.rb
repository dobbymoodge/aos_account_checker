require 'lib/openshift'
require 'lib/openshift/config'
require 'lib/openshift/ldap'
require 'lib/openshift/github'
require 'lib/openshift/trello_helper'
require 'rack/request'
require 'erb'

module OpenShift

  class ProfileData
    attr_accessor :uid, :mail,
                  :github_status, :github_reasons, :github_id,
                  :trello_status, :trello_reasons, :trello_id,
                  :redhat_status, :redhat_reasons, :redhat_id
    attr_accessor :trello_fullname, :trello_org_member, :trello_org

    def initialize()
      @github_status = CLASS_UNCHECKED
      @trello_status = CLASS_UNCHECKED
      @redhat_status = CLASS_UNCHECKED

      @github_reasons = []
      @trello_reasons = []
      @redhat_reasons = []
    end

    def get_binding()
      binding()
    end
  end

#module OpenShift
  class ProfileCheck

    VALID_EMAIL_DOMAIN = '@redhat.com'
    COMPANY_NAME = 'Red Hat'
    VALID_COMPANY_PATTERN = /^#{COMPANY_NAME}/

    # This loads the conf files and creates new objects based on the specified classes
    def load_conf(klass,args,single = false)
      if single
        klass.new(args)
      else
        Hash[*args.map do |key,val|
               [key,klass.new(val)]
             end.flatten]
      end
    end

    def ldap
      @ldap ||= load_conf(LdapHelper, CONFIG.ldap, true)
    end

    def trello
      @trello ||= load_conf(TrelloHelper, CONFIG.trello, true)
    end

    def github
      @github ||= load_conf(GitHubHelper, CONFIG.github, true)
    end

    def email_check(email)
      status = CLASS_INVALID
      if email && ldap.user_by_email(email)
        status = CLASS_VALID
      end
      status
    end

    def github_user_check(user_name)
      reasons = []
      status = CLASS_UNCHECKED
      if user_name && !user_name.empty?
        user = github.user(user_name)
        login = user['login']
        name = user['name']
        email = user['email']
        company = user['company']
        status = email_check(email)
        if status == CLASS_INVALID
          status, reasons = ldap.login_name_check(login, name)
        end
        if company !~ VALID_COMPANY_PATTERN
          status = CLASS_INVALID
          reasons += ["Profile Company field doesn't match \"#{COMPANY_NAME}\""]
        end
      end
      [status, reasons]
    end

    def trello_user_check(email, member)
      status = CLASS_UNCHECKED
      reasons = []
      if member
        login = member.username
        name = member.full_name
        member_reasons = nil
        status, member_reasons = login_name_check(login, name)
        reasons += member_reasons if member_reasons
      end
      [status, reasons]
    end

    def field_status_class(status)
      return CLASS_MAP[status]
    end

    def call(env)
      erb = ERB.new(File.open(File.expand_path("templates/form.erb"), "rb").read)
      pd = ProfileData.new()
      req = Rack::Request.new(env)
      trello_member = nil
      email = req.params['redhat_id'] if req.params['redhat_id']
      email = "#{email}#{VALID_EMAIL_DOMAIN}" if email && !email.include?('@')
      pd.redhat_id = email if email
      pd.github_id = req.params['github_id'] if req.params['github_id']
      pd.trello_id = req.params['trello_id'] if req.params['trello_id']
      # email = "#{req.params['redhat_id']}
      if email
        pd.redhat_status = email_check(email)
        pd.redhat_reasons = ["No valid user matches supplied email address #{email}"] if pd.redhat_status == CLASS_INVALID
      end
      begin
        pd.github_status, pd.github_reasons = github_user_check(pd.github_id) if req.params['github_id']
      rescue Exception => e
        msg = "GitHub User lookup failed: #{e.message}"
        puts msg
        pd.github_status = CLASS_ERROR
        pd.github_reasons = [msg]
      end
      if req.params['redhat_id']
        begin
          pd.trello_status, pd.trello_reasons, trello_member = trello.user_email_check(email, ldap)
          pd.trello_org = trello.org.display_name
          if trello_member
            pd.trello_fullname = trello_member.full_name
            pd.trello_id = trello_member.username
            pd.trello_org_member = trello.org_members_by_id.include? trello_member.id
          end
        rescue Exception => e
          msg = "Trello User lookup failed: #{e.message}"
          puts msg
          pd.trello_status = CLASS_ERROR
          pd.trello_reasons = [msg]
        end
      end
      form_content = erb.result(pd.get_binding)
      [200, { "Content-Type" => "text/html" }, [ form_content ]]
    end
  end
end
