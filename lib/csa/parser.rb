#!/usr/bin/env ruby

require "optparse"
require "csa/version"

class Parser
  def Parser.getParams
    default_project_name = "Demo"
    default_url = "https://github.com/djiangnz/swift-template.git"

    options = {}
    OptionParser.new do |opt|
      opt.on_tail("-h", "--help", "Prints help") { puts opt; exit }
      opt.on_tail("-y", "--yes", "Use default settings") { |o| options[:use_default] = true }
      opt.on_tail("-v", "--version", "Prints Version") { puts Csa::VERSION; exit }
      opt.on("-n", "--name NAME", "The Name of the project") { |o| options[:name] = o }
      opt.on("-u", "--url URL", "The URL of the template") { |o| raise "Git is required" unless system "which git > /dev/null"; options[:url] = o }
    end.parse!

    params = {}
    params[:project_name] = options[:name] ||= ARGV[0] ||= default_project_name
    params[:template_url] = options[:url] ||= ARGV[1] ||= default_url
    params[:use_default] = options[:use_default] == true
    params
  end
end
