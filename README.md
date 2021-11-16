# Rephrase - a gem for manipulating Ruby code

[![Gem Version](https://badge.fury.io/rb/rephrase.svg)](http://rubygems.org/gems/rephrase)
[![Modulation Test](https://github.com/digital-fabric/rephrase/workflows/Tests/badge.svg)](https://github.com/digital-fabric/rephrase/actions?query=workflow%3ATests)
[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/digital-fabric/rephrase/blob/master/LICENSE)

## Summary

Rephrase converts Ruby procs or methods to source code, allowing you to
reformat, reinterpret or otherwise manipulate the generated source code.
Possible uses include:

- Generating code from DSL blocks.
- Inlining loops.
- Macro exansion.
- World domination (???)

## How does it do it?

Rephrase uses the `RubyVM::AbstractSyntaxTree` API to get the AST of a proc or
method. This allows you to manipulate code at runtime, and to be able to access
its binding.

## How to use it

Use `Rephrase.to_source` to get the unmodified source code of a proc or method,
e.g.:

```ruby
require 'rephrase'

example = proc { 2 + 2 }
Rephrase.to_source(example) #=> "proc do\n2 + 2\nend"
```

## How to rephrase code

Further documentation is forthcoming...

## Limitations

- Works only on MRI.
- Ruby 2.7 or newer.
- Generated source code will not be formatted identically to the source
  (indentation, line breaks etc.)
