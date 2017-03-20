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
    attr_accessor :trello_fullname

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
      #email = "${redhat_id}#{VALID_EMAIL_DOMAIN}"
      status = CLASS_INVALID
      if email && ldap.user_by_email(email)
        status = CLASS_VALID
      end
      status
    end

    def login_name_check(login, name)
      reasons = []
      status = CLASS_INVALID
      valid, imperfect = ldap.valid_user_name(login, name)
      if valid
        if imperfect
          status = CLASS_IMPERFECT
          reasons += ["Profile Name field matches multiple users"]
        else
          status = CLASS_VALID
        end
      else
        status = CLASS_INVALID
        reasons += ["Profile Name field doesn't match any valid user"]
      end
      [status, reasons]
    end

    def github_user_check(user_name, rh_email)
      puts "github_user_check(#{user_name})"
      reasons = []
      status = CLASS_UNCHECKED
      if user_name && !user_name.empty?
        user = github.user(user_name)
        login = user['login']
        name = user['name']
        email = user['email']
        company = user['company']
        status = email_check(email)
        puts "1 github [status, reasons]: #{[status, reasons]}"
        if status == CLASS_INVALID
          status, reasons = login_name_check(login, name)
        end
        if email != rh_email
          status = CLASS_INVALID
          reasons += ["Red Hat email address #{rh_email} doesn't match GitHub email address #{email}"]
        end
        puts "2 github [status, reasons]: #{[status, reasons]}"
        if company !~ VALID_COMPANY_PATTERN
          status = CLASS_INVALID
          reasons += ["Profile Company field doesn't match \"#{COMPANY_NAME}\""]
        end
        puts "3 github [status, reasons]: #{[status, reasons]}"
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
      puts "trello [status, reasons]: #{[status, reasons]}"
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
      pd.redhat_id = req.params['redhat_id'] if req.params['redhat_id']
      pd.github_id = req.params['github_id'] if req.params['github_id']
      pd.trello_id = req.params['trello_id'] if req.params['trello_id']
      email = "#{req.params['redhat_id']}#{VALID_EMAIL_DOMAIN}" if req.params['redhat_id']
      pd.redhat_status = email_check(email)
      begin
        pd.github_status, pd.github_reasons = github_user_check(pd.github_id, email) if req.params['github_id']
      rescue Exception => e
        pd.github_status = CLASS_ERROR
        pd.github_reasons = [e.message]
        puts "Error with github: #{e.message}"
      end
      puts "[pd.github_status, pd.github_reasons]: #{[pd.github_status, pd.github_reasons]}"
      if req.params['redhat_id']
        begin
          begin
            trello_member = trello.member(email)
            if !trello_member
              pd.trello_status = CLASS_INVALID
            else
              pd.trello_status = CLASS_VALID
              pd.trello_id = trello_member.username
              pd.trello_fullname = trello_member.full_name
            end
          rescue Exception => e
            puts "Error with trello: #{e.message}"
            pd.trello_status = CLASS_INVALID
          end
          if pd.trello_status == CLASS_INVALID
            pd.trello_reasons += ["No matching Trello account found for email #{email}"]
          else
            pd.trello_status, trello_reasons = trello_user_check(email, trello_member)
            pd.trello_reasons += trello_reasons
          end
        rescue Exception => e
          pd.trello_status = CLASS_ERROR
          puts "Error with trello: #{e.message}"
        end
      end
      form_content = erb.result(pd.get_binding)
      [200, { "Content-Type" => "text/html" }, [ form_content ]]
    end
  end
end
