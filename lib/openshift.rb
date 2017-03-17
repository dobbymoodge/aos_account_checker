#!/usr/bin/env ruby

$: << File.expand_path(File.dirname(__FILE__))

module OpenShift
  DEFAULT_RETRIES = 3
  DEFAULT_RETRY_SLEEP = 0.5 #2
  DEFAULT_RETRY_INC = 0.5 #1

  CLASS_VALID = "valid"
  CLASS_INVALID = "invalid"
  CLASS_IMPERFECT = "imperfect"
  CLASS_ERROR = "error"
  CLASS_UNCHECKED = ""

  def retry_sleep(retry_count)
    sleep DEFAULT_RETRY_SLEEP + (DEFAULT_RETRY_INC * retry_count)
  end

  def retry_do(type, retries=DEFAULT_RETRIES)
    i = 0
    while true
      begin
        yield
        break
      rescue Exception => e
        $stderr.puts "Error with #{type}: #{e.message}"
        raise if i >= retries
        retry_sleep i
        i += 1
      end
    end
  end

end
