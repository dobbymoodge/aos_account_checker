#!/usr/bin/env ruby
# coding: utf-8

$: << File.expand_path(File.dirname(__FILE__))

require 'rack/lobster'
require 'net/ldap'
require 'lib/openshift'
require 'lib/openshift/profile_check'
require 'json'

use Rack::Static, :urls => ["/css", "/js", "/fonts"]

HOST        = 'ldap.rdu.redhat.com'
BASE_DN     = 'ou=Users, dc=redhat, dc=com'
ATTRS = ['uid', 'mail', 'cn']

map '/health' do
  health = proc do |env|
    [200, { "Content-Type" => "text/html" }, ["1"]]
  end
  run health
end

map '/lobster' do
  run Rack::Lobster.new
end

map '/tmp' do
  content = %{
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <!-- The above 3 meta tags *must* come first in the head; any other head content must come *after* these tags -->
    <title>AOS Profile Checker</title>

    <!-- Bootstrap -->
    <link href="css/bootstrap.min.css" rel="stylesheet">

    <!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
    <!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
    <!--[if lt IE 9]>
        <script src="https://oss.maxcdn.com/html5shiv/3.7.3/html5shiv.min.js"></script>
        <script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
        <![endif]-->
  </head>
  <body>
    <div class="div1" id="first_div">First div</div>
    <div class="div2" id="second_div">Second div</div>
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.12.4/jquery.min.js"></script>
    <!-- Include all compiled plugins (below), or include individual files as needed -->
    <script src="js/bootstrap.min.js"></script>
    <script src="js/profile_check.js"></script>
  </body>
</html>
}
  tmp = proc do |env|
    [200, { "Content-Type" => "text/html"}, [content]]
  end
  run tmp
end

map '/testjson' do
  ds_map = {'fail' => {:status => 'fail',
                       :reasons => ['bad thing 1 happened',
                                    'the russians invaded']},
            'pass' => {:status => 'pass',
                       :reasons => []},
            'warn' => {:status => 'warn',
                       :reasons => ["you didn't say the magic word",
                                    "i'm feeling gassy"]}}
  testjson = proc do |env|
    req = Rack::Request.new(env)
    ds = nil
    if req.params['status'] and ds_map.include?(req.params['status'])
      ds = ds_map[req.params['status']]
    end
    [200, { "Content-Type" => "text/json" }, [ds.to_json]]
  end
  run testjson
end

# <div class="div3" id="third_div">Third div</div>


# map '/' do
#   welcome = proc do |env|
#     [200, { "Content-Type" => "text/html" }, [<<WELCOME_CONTENTS
# howdy
# WELCOME_CONTENTS
#     ]]
#   end
#   run welcome
# end

map '/' do
  run OpenShift::ProfileCheck.new
end
