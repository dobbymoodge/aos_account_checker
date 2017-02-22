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

    def member(member_name)
      puts "TrelloHelper::Member"
      retry_do('Trello::Member') do
        return Trello::Member.find(member_name)
      end
    end

  end
# end
