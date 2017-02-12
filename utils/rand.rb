#!/usr/bin/env ruby
# Generate random pattern for testbenches

len   = ARGV[0].to_i
range = 256
mask  = 0xffff

len.times do |i|
  puts format("%.4x", rand(-range...range) & mask)
end

