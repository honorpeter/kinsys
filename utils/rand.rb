#!/usr/bin/env ruby
# Generate random pattern for testbenches

len   = ARGV[0].to_i
base  = 16
range = 256

len.times do |i|
  puts rand(-range...range).to_s(base)
end

