#!/usr/bin/ruby
require 'cgi'


cgi = CGI.new

# 'pattern' is repeatedly printed out ASAP until 'speed' is reached
# and until 'length' is filled up

# pattern:string - string which is printed out char by char repeatedly
pattern = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
# length:int - number of kB to reach by printing out
length = 50
# speed:int - number of kB/s
speed = 10

if cgi.key?('pattern') and cgi['pattern'].length > 0 and cgi['pattern'][0].length > 0
	pattern = cgi['pattern'][0].to_s
end
if cgi.key?('length')
	ln = cgi['length'].to_i
	if ln > 0 and ln < 500
		length = ln
	end
end
if cgi.key?('speed')
	sp = cgi['speed'].to_i
	if sp > 0 and sp < 400
		speed = sp
	end
end




bytes_requested = length * 1024
speed_requested = speed * 1024
bytes_counter = 0
speed_counter = 0

puts 'Content-Type: application/octet-stream'
puts 'Content-Length: '+bytes_requested.to_s
puts ''
while bytes_counter <  bytes_requested
	print(pattern[bytes_counter.modulo(pattern.length)].chr)
	bytes_counter += 1
	speed_counter += 1
	if speed_counter == speed_requested
		speed_counter = 0
		sleep(0.98)
	end
end

