require 'trello'

# module OpenShift
  class TrelloHelper
    include OpenShift
    attr_accessor :consumer_key, :consumer_secret, :oauth_token, :oauth_token_secret,
                  :organization_id, :organization_name

    def initialize(opts)
      opts.each do |k,v|
        send("#{k}=",v)
      end

      Trello.configure do |config|
        config.consumer_key = @consumer_key
        config.consumer_secret = @consumer_secret
        config.oauth_token = @oauth_token
        config.oauth_token_secret = @oauth_token_secret
      end
    end

    def target(ref, name='target')
      retry_do(name) do
        t = ref.target
        return t
      end
    end

    def member(member_name)
      retry_do('Trello::Member') do
        return Trello::Member.find(member_name)
      end
    end

    def org
      retry_do('org') do
        @org ||= Trello::Organization.find(organization_id)
        return @org
      end
    end

    def org_members
      retry_do('org_members') do
        return @org_members ||= target(org.members)
      end
    end

    def org_members_by_id
      if !@org_members_by_id
        @org_members_by_id = {}
        org_members.each { |m| @org_members_by_id[m.id] = m }
      end
      @org_members_by_id
    end

    def user_email_check(email, ldap)
      status = CLASS_UNCHECKED
      reasons = []
      user = nil
      if email
        begin
          user = member(email)
        rescue Exception => e
          # pass
        end
        if user
          login = user.username
          name = user.full_name
          member_reasons = nil
          status, member_reasons = ldap.login_name_check(login, name)
          reasons += member_reasons if member_reasons
        else
          status = CLASS_INVALID
          reasons += ["No matching Trello account found for email #{email}"]
        end
      end
      [status, reasons, user]
    end

  end
# end
