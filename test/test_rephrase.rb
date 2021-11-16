# frozen_string_literal: true

require 'bundler/setup'
require 'minitest/autorun'
require 'rephrase'

class APITest < Minitest::Test
  def test_to_ruby
    a = 1
    b = 2
    example = proc { a * b }
    source = Rephrase.to_ruby(example)
    assert_equal "proc do\na * b\nend", source
  end
end

class CodeConversionTest < Minitest::Test
  def ast_to_ruby(o = nil, &block)
    o ||= block
    ast = RubyVM::AbstractSyntaxTree.of(o)
    # Rephrase.pp_ast(ast)
    Rephrase.new.convert({}, ast)#.tap { |o| puts '*' * 40; puts o; puts }
  end

  module A
    module B
      module C
      end
    end
  end

  def test_const1
    code = ast_to_ruby { foo A }
    assert_equal "proc do\nfoo(A)\nend", code
  end

  def test_const2
    code = ast_to_ruby { foo A::B }
    assert_equal "proc do\nfoo(A::B)\nend", code
  end

  def test_const3
    code = ast_to_ruby { foo A::B::C }
    assert_equal "proc do\nfoo(A::B::C)\nend", code
  end

  def test_const4
    code = ast_to_ruby { foo A::B::C.d }
    assert_equal "proc do\nfoo(A::B::C.d())\nend", code
  end

  def test_str1
    code = ast_to_ruby { 'a' }
    assert_equal "proc do\n\"a\"\nend", code
  end

  def test_str2
    code = ast_to_ruby { "a\nb" }
    assert_equal "proc do\n\"a\\nb\"\nend", code
  end

  def test_nil1
    code = ast_to_ruby { foo(nil) }
    assert_equal "proc do\nfoo(nil)\nend", code
  end

  def test_true1
    code = ast_to_ruby { foo(true) }
    assert_equal "proc do\nfoo(true)\nend", code
  end

  def test_false1
    code = ast_to_ruby { foo(false) }
    assert_equal "proc do\nfoo(false)\nend", code
  end

  def test_fcall1
    code = ast_to_ruby { p 1 }
    assert_equal "proc do\np(1)\nend", code
  end

  def test_fcall2
    code = ast_to_ruby { foo :a, :b, :c }
    assert_equal "proc do\nfoo(:a, :b, :c)\nend", code
  end

  def test_fcall3
    code = ast_to_ruby { foo a: 1, b: 2 }
    assert_equal "proc do\nfoo({:a => 1, :b => 2})\nend", code
  end

  def test_fcall4
    code = ast_to_ruby { foo 'bar', a: 1, b: 2 }
    assert_equal "proc do\nfoo(\"bar\", {:a => 1, :b => 2})\nend", code
  end

  def test_fcall5
    code = ast_to_ruby { foo('bar', a: 1, b: 2) { |x| x + 1 } }
    assert_equal "proc do\nfoo(\"bar\", {:a => 1, :b => 2}) do |x|\nx + 1\nend\nend", code
  end

  def test_fcall6
    code = ast_to_ruby { foo { bar { baz 'a' } } }
    assert_equal "proc do\nfoo() do\nbar() do\nbaz(\"a\")\nend\nend\nend", code
  end

  def test_vcall1
    code = ast_to_ruby { foo; bar }
    assert_equal "proc do\nfoo()\nbar()\nend", code
  end

  def test_assign1
    code = ast_to_ruby { a = 1; p a }
    assert_equal "proc do\na = 1\np(a)\nend", code
  end

  def test_assign2
    code = ast_to_ruby { a = 2 + 2 }
    assert_equal "proc do\na = 2 + 2\nend", code
  end

  def test_ternary1
    code = ast_to_ruby { foo ? bar : baz }
    assert_equal "proc do\nif foo()\nbar()\nelse\nbaz()\nend\nend", code
  end

  def test_if_guard1
    code = ast_to_ruby { foo if baz }
    assert_equal "proc do\nif baz()\nfoo()\nend\nend", code
  end

  def test_if1
    code = ast_to_ruby { if foo; baz; end }
    assert_equal "proc do\nif foo()\nbaz()\nend\nend", code
  end

  def test_and1
    code = ast_to_ruby { if foo && bar; baz; end }
    assert_equal "proc do\nif foo() && bar()\nbaz()\nend\nend", code
  end

  def test_or1
    code = ast_to_ruby { if foo || bar; baz; end }
    assert_equal "proc do\nif foo() || bar()\nbaz()\nend\nend", code
  end

  def test_not1
    code = ast_to_ruby { foo if !bar }
    assert_equal "proc do\nif !(bar())\nfoo()\nend\nend", code
  end

  def test_not2
    code = ast_to_ruby { a = !b }
    assert_equal "proc do\na = !(b())\nend", code
  end

  def test_eq1
    code = ast_to_ruby { foo if bar == baz }
    assert_equal "proc do\nif bar() == baz()\nfoo()\nend\nend", code
  end

  def test_local1
    a = 1
    code = ast_to_ruby { foo(a) }
    assert_equal "proc do\nfoo(a)\nend", code
  end

  def test_local2
    a = 1
    code = ast_to_ruby { a.foo }
    assert_equal "proc do\na.foo()\nend", code
  end

  def test_call1
    a = 1
    code = ast_to_ruby { a.foo(1) }
    assert_equal "proc do\na.foo(1)\nend", code
  end

  def test_call2
    a = 1
    code = ast_to_ruby { a.foo(1, 'a') }
    assert_equal "proc do\na.foo(1, \"a\")\nend", code
  end

  def test_call3
    a = 1
    code = ast_to_ruby { a.foo(1, [bar]) }
    assert_equal "proc do\na.foo(1, [bar()])\nend", code
  end

  def test_subscript1
    a = 1
    code = ast_to_ruby { foo a[:bar] }
    assert_equal "proc do\nfoo(a[:bar])\nend", code
  end

  def test_subscript2
    a = 1
    code = ast_to_ruby { a[1] = b }
    assert_equal "proc do\na[1] = b()\nend", code
  end

  def test_subscript3
    a = 1
    code = ast_to_ruby { a[:foo, 'bar'] = b }
    assert_equal "proc do\na[:foo, \"bar\"] = b()\nend", code
  end

  def test_interpolated_string1
    a = 1
    b = 2
    code = ast_to_ruby { foo "--#{a.to_s(16)}**\nbar#{b + 1}" }
    assert_equal "proc do\nfoo(\"--\#{a.to_s(16)}**\\nbar\#{b + 1}\")\nend", code
  end

  def test_interpolated_string2
    a = 1
    b = 2
    code = ast_to_ruby { foo "#{0}--#{1}**\nbar#{2}\t#{3}" }
    assert_equal "proc do\nfoo(\"\#{0}--\#{1}**\\nbar\#{2}\\t\#{3}\")\nend", code
  end

  def test_array1
    code = ast_to_ruby { 
      a = [1, 2, 3]
      foo(a)
    }
    assert_equal "proc do\na = [1, 2, 3]\nfoo(a)\nend", code

  end

  def test_hash1
    code = ast_to_ruby { 
      a = { a: 1, 'blah' => 2 }
      foo(a)
    }
    assert_equal "proc do\na = {:a => 1, \"blah\" => 2}\nfoo(a)\nend", code
  end

  def test_ivar1
    code = ast_to_ruby { foo @bar }
    assert_equal "proc do\nfoo(@bar)\nend", code
  end

  def test_ivar2
    code = ast_to_ruby { @bar = foo }
    assert_equal "proc do\n@bar = foo()\nend", code
  end

  def test_unless1
    code = ast_to_ruby { foo(:bar) unless 1 }
    assert_equal "proc do\nunless 1\nfoo(:bar)\nend\nend", code
  end

  def test_unless2
    code = ast_to_ruby {
      unless 1
        foo
      else
        bar
      end
    }
    assert_equal "proc do\nunless 1\nfoo()\nelse\nbar()\nend\nend", code
  end

  def test_while1
    code = ast_to_ruby {
      foo while bar
    }
    assert_equal "proc do\nwhile bar()\nfoo()\nend\nend", code
  end

  def test_while2
    code = ast_to_ruby {
      while 1 && 2
        foo
      end
    }
    assert_equal "proc do\nwhile 1 && 2\nfoo()\nend\nend", code
  end

  ##############################################################################

  def test_real_world1
    code = ast_to_ruby {
      rss(version: '2.0', 'xmlns:atom' => 'http://www.w3.org/2005/Atom') {
        channel {
          title 'Noteflakes'
          link 'https://noteflakes.com/'
          description 'A website by Sharon Rosner'
          language 'en-us'
          pubDate Time.now.httpdate
          emit '<atom:link href="https://noteflakes.com/feeds/rss" rel="self" type="application/rss+xml" />'
          context[:articles].each { |a|
            item {
              title a.title
              link "https://noteflakes.com#{a.permalink}"
              guid "https://noteflakes.com#{a.permalink}"
              pubDate a.attributes['date'].to_time.httpdate
              description (a.render rescue '?')
            }  
          }
        }
      }
    }
  end
end
