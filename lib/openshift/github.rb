require 'rest_client'
require 'json'

RESULTS_PER_PAGE=100

def github_user(user)
  params = access_params
  url = "https://api.github.com/users/#{user}"
  puts "url: #{url}"
  result = RestClient.get(url, {:params => params})
  JSON.parse(result)
end

private

def access_params(require_access_token=true)
  params = {:per_page => RESULTS_PER_PAGE}
  puts "ENV['GH_ACCESS_TOKEN']: #{ENV['GH_ACCESS_TOKEN']}"
  access_token = ENV['GH_ACCESS_TOKEN']
  puts "access_token: #{access_token}"
  if access_token
    params[:access_token] = access_token
    puts "params[:access_token] #{params[:access_token]}"
  elsif require_access_token
    raise "Missing environment variable: GH_ACCESS_TOKEN"
  end
  params
end
