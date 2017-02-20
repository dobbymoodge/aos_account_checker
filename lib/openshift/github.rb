require 'rest_client'
require 'json'

RESULTS_PER_PAGE=100

def github_user(user)
  params = access_params(false)
  url = "https://api.github.com/users/#{user}"
  result = RestClient.get(url, {:params => params})
  JSON.parse(result)
end

private

def access_params(require_access_token=true)
  params = {:per_page => RESULTS_PER_PAGE}
  access_token = ENV.include? 'GH_ACCESS_TOKEN' ? ENV['GH_ACCESS_TOKEN'] : nil
  if access_token
    params[:access_token] = access_token
  elsif require_access_token
    raise "Missing environment variable: GH_ACCESS_TOKEN"
  end
  params
end
