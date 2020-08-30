#!/usr/bin/env ruby

require "csa/app"
require "csa/parser"
require "date"

# ============== MAIN ==============
params = Parser.getParams
App.new(name: params[:project_name], template_dir: params[:template_dir], template_url: params[:template_url]).run
