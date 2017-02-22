require 'rest_client'
require 'json'

RESULTS_PER_PAGE=100

# module OpenShift
  class GitHubHelper
    include OpenShift
    attr_accessor :gh_access_token

    def initialize(opts)
      opts.each do |k,v|
        send("#{k}=",v)
      end
    end

    def user(user)
      puts "GitHubHelper::user"
      params = access_params
      url = "https://api.github.com/users/#{user}"
      puts "url: #{url}"
      user_result = nil
      retry_do('GitHubHelper.user') do
        result = RestClient.get(url, {:params => params})
        user_result = JSON.parse(result)
      end
      user_result
    end

    private

    def access_params(require_access_token=true)
      params = {:per_page => RESULTS_PER_PAGE}
      if @gh_access_token
        params[:access_token] = @gh_access_token
      elsif require_access_token
        raise "Missing GitHub access token in configuration"
      end
      params
    end
  end
# end
