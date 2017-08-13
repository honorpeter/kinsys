#!/usr/bin/env ruby

require 'fileutils'

base_dir    = "/home/work/takau/2.mlearn/models_chainer"
input_dir   = "#{base_dir}/mnist/test"
param_dir   = "#{base_dir}/lenet"
input_label = ARGV[0].to_i
input_name  = ARGV[1].to_i

def hex_of_floatfile(path)
  float = File.open(path).readlines.map {|line| line.to_f * 256}
  float.map {|num| format("  0b%.16b,", num.to_i & 0xffff)}
end

FileUtils.mkdir_p("src/data")

image = hex_of_floatfile("#{input_dir}/#{input_label}/img#{input_name}.dat")
File.open("src/data/image.h", "w") do |f|
  f.puts <<~EOS
    #ifndef _IMAGE_H_
    #define _IMAGE_H_

    // PATH: #{input_dir}/#{input_label}/img#{input_name}.dat
    static s16 image[#{image.length}] = {
    #{image.join("\n")}
    };

    #endif
  EOS
end

Dir.glob("#{param_dir}/*") do |layer_path|
  layer = File.basename(layer_path)

  ["W", "b"].each do |type|
    param = hex_of_floatfile("#{layer_path}/#{type}.dat")
    File.open("src/data/#{type}_#{layer}.h", "w") do |f|
      f.puts <<~EOS
        #ifndef _#{type.upcase}_#{layer.upcase}_H_
        #define _#{type.upcase}_#{layer.upcase}_H_

        // PATH: #{layer_path}/#{type}.dat
        static u32 #{type}_#{layer}[#{param.length}] = {
        #{param.join("\n")}
        };

        #endif
      EOS
    end
  end
end

