#!/usr/bin/env ruby

require "csa/app"
require "csa/parser"
require "date"

# ============== MAIN ==============
params = Parser.getParams
App.new(params).run
