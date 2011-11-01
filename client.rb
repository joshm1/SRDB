#!/usr/bin/env ruby

# I used this to test the server when developing on a headless box
# Prints the HTTP response and response body

require 'socket'
HOST = ARGV[0] || '127.0.0.1'
PORT = ARGV[1] || '8080'

while true
  v, s = nil, (TCPSocket.new HOST, PORT)
  print "Request Path > "
  path = gets
  break unless path
  path.chomp!
  
  puts " Request ".center(80, '=')
  request = "GET #{path} HTTP/1.0"
  s.puts request
  puts request
  
  puts " Response ".center(80, '=')
  puts v while (v = s.gets)
  puts "=" * 80
  s.close
end
