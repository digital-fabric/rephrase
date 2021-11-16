# frozen_string_literal: true

# for use with IRB, see https://dev.to/okinawarb/how-can-i-use-rubyvm-abstractsyntaxtree-in-irb-m2k
# for use in Pry, see https://dev.to/okinawarb/using-rubyvm-abstractsyntaxtree-of-in-pry-4cm3

class Rephrase
  class FakeNode
    def self.list(children)
      new(:LIST_EMBEDDED, children)
    end

    def self.iter_scope(children)
      new(:ITER_SCOPE, children)
    end

    attr_reader :type, :children
    
    def initialize(type, children)
      @type = type
      @children = children
    end
  end

  def convert(ctx, node)
    ctx[:buffer] ||= +''
    ctx[:indent] ||= 0
    method_name = :"on_#{node.type.downcase}"
    if respond_to?(method_name)
      send(method_name, ctx, node)
      ctx[:buffer]
    else
      raise "Could not convert #{node.type} node to ruby"
    end
  end

  def on_scope(ctx, node)
    body = node.children.last
    # if body.type != :BLOCK
    #   body = FakeNode.new(:BLOCK, [body])
    # end
    emit(ctx, "proc do", [body], "end")
  end

  def on_block(ctx, node)
    last_idx = node.children.size - 1
    node.children.each_with_index do |c, idx|
      emit(ctx, c)
      emit(ctx, "\n") if idx < last_idx
    end
  end

  def on_iter(ctx, node)
    call, scope = node.children
    emit(ctx, call)
    emit(ctx, FakeNode.iter_scope(scope.children))
  end

  def on_iter_scope(ctx, node)
    args, arg_spec, body = node.children
    emit(ctx, " do")
    emit(ctx, " |", args.map(&:to_s).join(", "), "|") unless args.empty?
    emit(ctx, "\n")
    emit(ctx, body)
    emit(ctx, "\nend")
  end

  def on_const(ctx, node)
    emit(ctx, node.children.first.to_s)
  end

  def on_colon2(ctx, node)
    left, right = node.children
    emit(ctx, left, "::", right.to_s)
  end

  def on_call(ctx, node)
    receiver, method, args = node.children
    args = args && FakeNode.list(args.children)
    case method
    when :[]
      emit(ctx, receiver, "[", args, "]")
    else
      if args
        emit(ctx, receiver, ".", "#{method}(", args, ")")
      else
        emit(ctx, receiver, ".", "#{method}()")
      end
    end
  end

  def on_fcall(ctx, node)
    method, args = node.children
    args = args && FakeNode.list(args.children)
    emit(ctx, "#{method}(", args, ")")
  end

  def on_vcall(ctx, node)
    emit(ctx, node.children.first.to_s, "()")
  end

  def on_opcall(ctx, node)
    left, op, right = node.children
    if op == :!
      emit(ctx, "!(", left, ")")
    else
      emit(ctx, left, " #{op} ", right.children.first)
    end
  end

  def on_dasgn_curr(ctx, node)
    left, right = node.children
    emit(ctx, left.to_s, " = ", right)
  end

  def on_iasgn(ctx, node)
    left, right = node.children
    emit(ctx, left.to_s, " = ", right)
  end

  def on_if(ctx, node)
    cond, branch1, branch2 = node.children
    if branch2
      emit(ctx, "if ", cond, "\n", branch1, "\nelse\n", branch2, "\nend")
    else
      emit(ctx, "if ", cond, "\n", branch1, "\nend")
    end
  end

  def on_unless(ctx, node)
    cond, branch1, branch2 = node.children
    if branch2
      emit(ctx, "unless ", cond, "\n", branch1, "\nelse\n", branch2, "\nend")
    else
      emit(ctx, "unless ", cond, "\n", branch1, "\nend")
    end
  end

  def on_while(ctx, node)
    cond, body = node.children
    emit(ctx, "while ", cond, "\n", body, "\nend")
  end

  def on_lit(ctx, node)
    emit(ctx, node.children.first.inspect)
  end

  def on_nil(ctx, node)
    emit(ctx, "nil")
  end

  def on_true(ctx, node)
    emit(ctx, "true")
  end

  def on_false(ctx, node)
    emit(ctx, "false")
  end

  def on_dvar(ctx, node)
    emit(ctx, node.children.first.to_s)
  end

  def on_ivar(ctx, node)
    emit(ctx, node.children.first.to_s)
  end

  def on_str(ctx, node)
    emit(ctx, node.children.first.inspect)
  end

  def on_dstr(ctx, node)
    prefix, evstr1, rest = node.children
    emit(ctx, "\"", prefix.inspect[1..-2], evstr1)
    if rest
      rest.children.compact.each do |n|
        case n.type
        when :STR
          emit(ctx, n.children.first.inspect[1..-2])
        when :EVSTR
          emit(ctx, n)
        else
          raise "Unexpected node #{n.type.inspect} encountered in DSTR"
        end
      end
    end
    emit(ctx, "\"")
  end

  def on_evstr(ctx, node)
    emit(ctx, "\#{", node.children.first, "}")
  end

  def on_and(ctx, node)
    left, right = node.children
    emit(ctx, left, " && ", right)
  end

  def on_or(ctx, node)
    left, right = node.children
    emit(ctx, left, " || ", right)
  end

  def on_list(ctx, node)
    items = node.children[0..-2]
    last_idx = items.size - 1
    emit(ctx, "[")
    items.each_with_index do |c, idx|
      emit(ctx, c)
      emit(ctx, ", ") if idx < last_idx
    end
    emit(ctx, "]")
  end

  def on_list_embedded(ctx, node)
    items = node.children.compact
    last_idx = items.size - 1
    items.each_with_index do |c, idx|
      emit(ctx, c)
      emit(ctx, ", ") if idx < last_idx
    end
  end

  def on_hash(ctx, node)
    list = node.children.first
    idx = 0
    emit(ctx, "{")
    while true
      k, v = list.children[idx, 2]
      break unless k

      emit(ctx, ", ") if idx > 0
      idx += 2
      emit(ctx, k, " => ", v)
    end
    emit(ctx, "}")
  end

  def on_attrasgn(ctx, node)
    left, op, args = node.children
    emit(ctx, left)
    case op
    when :[]=
      args_list = args.children[0..-2]
      subscript = FakeNode.list(args_list[0..-2])
      right = args_list.last
      emit(ctx, "[", subscript, "] = ", right)
    else
      raise "Unsupported ATTRASGN op #{op.inspect}"
    end
  end

  def on_rescue(ctx, node)
    code, rescue_body = node.children
    emit(ctx, code)
    emit(ctx, " rescue ", rescue_body.children[1])
  end

  def emit(ctx, *entries)
    entries.each do |e|
      case e
      when RubyVM::AbstractSyntaxTree::Node, FakeNode
        convert(ctx, e)
      when Array
        ctx[:buffer] << "\n"
        e.each { |e2| convert(ctx, e2) }
        ctx[:buffer] << "\n"
      when String
        ctx[:buffer] << e
      when nil
        # ignore
      else
        raise "Invalid entry #{e.inspect}"
      end
    end
  end
end
