# frozen_string_literal: true

require 'bundler/setup'
require 'rephrase'

example = proc { a * b }

code = Rephrase.to_ruby(example)
puts code