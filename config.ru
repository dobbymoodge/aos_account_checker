#!/usr/bin/env ruby
# coding: utf-8

$: << File.expand_path(File.dirname(__FILE__))

require 'rack/lobster'
require 'net/ldap'
require 'lib/openshift/ldap'
require 'lib/openshift/profile_check'

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

map '/' do
  run OpenShift::ProfileCheck.new
end

# map '/' do
#   welcome = proc do |env|
#     [200, { "Content-Type" => "text/html" }, [<<WELCOME_CONTENTS
# howdy
# WELCOME_CONTENTS
#     ]]
#   end
#   run welcome
# end
