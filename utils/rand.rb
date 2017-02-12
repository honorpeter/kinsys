#!/usr/bin/env ruby
# Generate random pattern for testbenches

require 'pp'

len = ARGV[0].to_i
range = 256

(-range...range).to_a.sample(len).each do |i|
  puts(i)
end

