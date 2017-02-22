require 'lib/openshift'
require 'lib/openshift/config'
require 'lib/openshift/ldap'
require 'lib/openshift/github'
require 'lib/openshift/trello_helper'
require 'rack/request'
require 'erb'

module OpenShift
  class ProfileData
    attr_accessor :uid, :req, :mail,
                  :github_status, :github_reasons, :github_id,
                  :trello_status, :trello_reasons, :trello_id,
                  :redhat_status, :redhat_reasons, :redhat_id

    def initialize()
      @github_status = :unchecked
      @trello_status = :unchecked
      @redhat_status = :unchecked

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
      #email = "${redhat_id}#{VALID_EMAIL_DOMAIN}"
      status = :invalid
      if email && ldap.user_by_email(email)
        status = :valid
      end
      status
    end

    def login_name_check(login, name)
      reasons = []
      status = :invalid
      valid, imperfect = ldap.valid_user_name(login, name)
      if valid
        if imperfect
          status = :imperfect
          reasons += ["Profile Name field matches multiple users"]
        else
          status = :valid
        end
      else
        status = :invalid
        reasons += ["Profile Name field doesn't match any valid user"]
      end
      [status, reasons]
    end

    def github_user_check(user_name)
      puts "github_user_check(#{user_name})"
      user = github.user(user_name)
      login = user['login']
      name = user['name']
      email = user['email']
      company = user['company']
      reasons = []
      status = email_check(email)
      puts "1 github [status, reasons]: #{[status, reasons]}"
      if status == :invalid
        status, reasons = login_name_check(login, name)
      end
      puts "2 github [status, reasons]: #{[status, reasons]}"
      if company !~ VALID_COMPANY_PATTERN
        status = :invalid
        reasons += ["Profile Company field doesn't match \"#{COMPANY_NAME}\""]
      end
      puts "3 github [status, reasons]: #{[status, reasons]}"
      [status, reasons]
    end

    def trello_user_check(email)
      status = :unchecked
      reasons = []
      member = nil
      begin
        member = trello.member(email)
      rescue Exception => e
        status = :invalid
        reasons += ["No matching Trello account found for email #{email}"]
      end
      if member
        login = member.username
        name = member.full_name
        member_reasons = nil
        status, member_reasons = login_name_check(login, name)
        reasons += member_reasons if member_reasons
      end
      puts "trello [status, reasons]: #{[status, reasons]}"
      [status, reasons]
    end

    def call(env)
      erb = ERB.new(File.open(File.expand_path("templates/form.erb"), "rb").read)
      pd = ProfileData.new()
      pd.req = Rack::Request.new(env)
      pd.redhat_id = pd.req.params['redhat_id'] if pd.req.params['redhat_id']
      pd.github_id = pd.req.params['github_id'] if pd.req.params['github_id']
      pd.trello_id = pd.req.params['trello_id'] if pd.req.params['trello_id']
      email = "#{pd.req.params['redhat_id']}#{VALID_EMAIL_DOMAIN}" if pd.req.params['redhat_id']
      pd.redhat_status = email_check(email)
      begin
        pd.github_status, pd.github_reasons = github_user_check(pd.github_id) if pd.req.params['github_id']
      rescue Exception => e
        pd.github_status = :error
        puts "Error with github: #{e.message}"
      end
      puts "[pd.github_status, pd.github_reasons]: #{[pd.github_status, pd.github_reasons]}"
      begin
        pd.trello_status, pd.trello_reasons = trello_user_check(email) if pd.req.params['redhat_id']
      rescue Exception => e
        pd.trello_status = :error
        puts "Error with trello: #{e.message}"
      end
      form_content = erb.result(pd.get_binding)
      [200, { "Content-Type" => "text/html" }, [ form_content ]]
    end
  end
end
