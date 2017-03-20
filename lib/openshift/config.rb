#!/usr/bin/env ruby

require 'yaml'
require 'ostruct'

module OpenShift
  CONFIG_DIR = if (ENV.include?("LDAPCHECK_CONFIG_DIR") && File.directory?(ENV["LDAPCHECK_CONFIG_DIR"]) && File.readable?(ENV["LDAPCHECK_CONFIG_DIR"]))
    File.expand_path(ENV["LDAPCHECK_CONFIG_DIR"])
  else
    File.expand_path(File.join(File.dirname(__FILE__),'../..','config'))
  end

  config_files = Dir.glob("#{CONFIG_DIR}/*.yml")
  hashes = {}

  config_files.each do |file|
    name = File.basename(file,".yml")
    hashes[name] = YAML.load_file(file)
  end

  CONFIG = OpenStruct.new(hashes)

end
