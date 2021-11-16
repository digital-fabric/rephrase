# frozen_string_literal: true

require 'bundler/setup'
require 'rephrase'

example = proc { a * b }

code = Rephrase.to_source(example)
puts code