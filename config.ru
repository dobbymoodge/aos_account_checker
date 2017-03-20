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

map '/' do
  run OpenShift::ProfileCheck.new
end
