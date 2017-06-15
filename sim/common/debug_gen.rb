#!/usr/bin/env ruby

input_label = ARGV[0].to_i
input_name  = ARGV[1].to_i

def hex_of_floatfile(path)
  float = File.open(path).readlines.map {|line| line.to_f * 256}
  float.map {|num| format("%.4x", num.to_i & 0xffff)}
end

input   = hex_of_floatfile("/home/work/takau/2.mlearn/models_chainer/mnist/test/#{input_label}/img#{input_name}.dat")
weight0 = hex_of_floatfile("/home/work/takau/2.mlearn/models_chainer/lenet/conv0/W.dat")
bias0   = hex_of_floatfile("/home/work/takau/2.mlearn/models_chainer/lenet/conv0/b.dat")
weight1 = hex_of_floatfile("/home/work/takau/2.mlearn/models_chainer/lenet/conv1/W.dat")
bias1   = hex_of_floatfile("/home/work/takau/2.mlearn/models_chainer/lenet/conv1/b.dat")

weight2 = hex_of_floatfile("/home/work/takau/2.mlearn/models_chainer/lenet/full2/W.dat")
bias2   = hex_of_floatfile("/home/work/takau/2.mlearn/models_chainer/lenet/full2/b.dat")
weight3 = hex_of_floatfile("/home/work/takau/2.mlearn/models_chainer/lenet/full3/W.dat")
bias3   = hex_of_floatfile("/home/work/takau/2.mlearn/models_chainer/lenet/full3/b.dat")

File.write("../../data/common/#{input_label}_img#{input_name}.dat", input.join("\n"))
File.write("../../data/common/W_conv0.dat", weight0.join("\n"))
File.write("../../data/common/b_conv0.dat", bias0.join("\n"))
File.write("../../data/common/W_conv1.dat", weight1.join("\n"))
File.write("../../data/common/b_conv1.dat", bias1.join("\n"))

File.write("../../data/common/W_full2.dat", weight2.join("\n"))
File.write("../../data/common/b_full2.dat", bias2.join("\n"))
File.write("../../data/common/W_full3.dat", weight3.join("\n"))
File.write("../../data/common/b_full3.dat", bias3.join("\n"))

