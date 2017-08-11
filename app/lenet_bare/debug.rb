#!/usr/bin/env ruby

def hex_of_decfile(path)
  dec = File.open(path).readlines.map {|line| line.to_i(16)}
  dec.map {|num| format("  0b%.16b,", num & 0xffff)}
end

["conv0", "conv1", "full2", "full3"].each do |layer|
  tru_dat = hex_of_decfile("../../data/common/#{layer}_tru.dat")
  File.open("src/data/#{layer}_tru.h", "w") do |f|
    f.puts <<~EOS
      #ifndef _#{layer.upcase}_TRU_H_
      #define _#{layer.upcase}_TRU_H_

      static s16 #{layer}_tru[#{tru_dat.length}] = {
      #{tru_dat.join("\n")}
      };

      #endif
    EOS
  end
end

