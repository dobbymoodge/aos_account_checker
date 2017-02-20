require 'net/ldap'
require 'pp'
require 'erb'


def ldap_connect
  ldap = Net::LDAP.new(host: HOST, port: 389)
  ldap
end

def ldap_user_by_uid(uid)
  user = nil
  ldap = ldap_connect
  if ldap.bind
    ldap.search(base: BASE_DN, scope: Net::LDAP::SearchScope_WholeSubtree, filter: "(uid=#{uid})", attribute: ATTRS) do |entry|
      #email = entry.vals('mail')[0]
      user = entry
    end
  end
  user
end
