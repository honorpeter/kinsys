#!/usr/bin/env ruby
# Making Tree diagram
# Input: Number of Leaves (corresponds to the number of multipliers)
# Output: the least height binary tree that covers all leaves given
#         (corresponds to the tree multiply-add unit.)
#
# Practically, we should generate verilog description.

def gen_root(define, assign, target, opeA)
  define.concat("  wire signed [DWIDTH-1:0] #{target};\n")
  assign.concat("  assign #{target} = #{opeA};\n")
end

def gen_node(define, assign, target, opeA, opeB)
  define.concat("  wire signed [DWIDTH-1:0] #{target};\n")
  assign.concat("  assign #{target} = #{opeA} + #{opeB};\n")
end

def make_tree(define, assign, out, add, mul, num_leaf, depth_rem=0, rank=0)
  has_rem = !depth_rem.zero?

  # Boundary
  if num_leaf == 1 && !has_rem then
    if rank == 0 then
      gen_root(define, assign, out, "#{mul}[0]");
    else
      gen_root(define, assign, out, "#{add}#{rank-1}_0");
    end
    return
  end

  # Recursive
  if num_leaf.even? then
    if has_rem then
    # even and rem
      num_node = num_leaf / 2
      if rank == 0 then
        num_node.times do |i|
          gen_node(define, assign, "#{add}#{rank}_#{i}", "#{mul}[#{2*i}]", "#{mul}[#{2*i+1}]")
        end
      else
        num_node.times do |i|
          gen_node(define, assign, "#{add}#{rank}_#{i}", "#{add}#{rank-1}_#{2*i}", "#{add}#{rank-1}_#{2*i+1}")
        end
      end
      make_tree(define, assign, out, add, mul, num_node, depth_rem+1, rank+1)
    else
    # even and no rem
      num_node = num_leaf / 2
      if rank == 0 then
        num_node.times do |i|
          gen_node(define, assign, "#{add}#{rank}_#{i}", "#{mul}[#{2*i}]", "#{mul}[#{2*i+1}]")
        end
      else
        num_node.times do |i|
          gen_node(define, assign, "#{add}#{rank}_#{i}", "#{add}#{rank-1}_#{2*i}", "#{add}#{rank-1}_#{2*i+1}")
        end
      end
      make_tree(define, assign, out, add, mul, num_node, 0, rank+1)
    end
  else
    if has_rem then
    # odd and rem
      num_node = num_leaf / 2 + 1
      if depth_rem == rank then
        (num_node-1).times do |i|
          gen_node(define, assign, "#{add}#{rank}_#{i}", "#{add}#{rank-1}_#{2*i}", "#{add}#{rank-1}_#{2*i+1}")
        end
        # TODO: yami (maybe num_leaf)
        gen_node(define, assign, "#{add}#{rank}_#{num_node-1}", "#{add}#{rank-1}_#{2*(num_node-1)}", "#{mul}[#{2*num_leaf*(2**(rank-1))}]")
      else
        (num_node-1).times do |i|
          gen_node(define, assign, "#{add}#{rank}_#{i}", "#{add}#{rank-1}_#{2*i}", "#{add}#{rank-1}_#{2*i+1}")
        end
        gen_node(define, assign, "#{add}#{rank}_#{num_node-1}", "#{add}#{rank-1}_#{2*(num_node-1)}", "#{add}#{rank-1-depth_rem}_#{2*num_leaf*(2**(depth_rem-1))}")
      end
      make_tree(define, assign, out, add, mul, num_node, 0, rank+1)
    else
    # odd and no rem
      num_node = num_leaf / 2
      if rank == 0 then
        num_node.times do |i|
          gen_node(define, assign, "#{add}#{rank}_#{i}", "#{mul}[#{2*i}]", "#{mul}[#{2*i+1}]")
        end
      else
        num_node.times do |i|
          gen_node(define, assign, "#{add}#{rank}_#{i}", "#{add}#{rank-1}_#{2*i}", "#{add}#{rank-1}_#{2*i+1}")
        end
      end
      make_tree(define, assign, out, add, mul, num_node, depth_rem+1, rank+1)
    end
  end
end

def main()
  out = "fmap"
  add = "sum"
  mul = "pro_short"
  num = ARGV[0].to_i
  define = ""
  assign = ""

  make_tree(define, assign, out, add, mul, num)

  puts define
  puts
  puts assign
end

main()

