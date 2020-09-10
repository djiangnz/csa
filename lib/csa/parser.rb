#!/usr/bin/env ruby

require "optparse"

class Parser
  def Parser.getParams
    default_project_name = "Demo"
    default_url = "https://github.com/dianyij/swift-template.git"

    options = {}
    OptionParser.new do |opt|
      opt.on_tail("-h", "--help", "Prints help") { puts opt; exit }
      opt.on("-n", "--name NAME", "The Name of the project") { |o| options[:name] = o }
      opt.on("-d", "--dir DIR", "The DIR of the template") { |o| raise "Directory does NOT exist" unless File.directory?(o); options[:dir] = o }
      opt.on("-u", "--url URL", "The URL of the template") { |o| raise "Git is required" unless system "which git > /dev/null"; options[:url] = o }
    end.parse!

    if options.empty?
      project_name = ARGV[0] ||= default_project_name
      template_url = ARGV[1] ||= default_url
    else
      project_name = options[:name] ||= ARGV[0]
      template_dir = options[:dir] ||= ""
      template_url = options[:url] ||= ""

      raise "Url or Dir is required" if options[:url].empty? && options[:dir].empty?
      app = App.new(name: project_name, template_url: template_url, template_dir: template_dir)
    end

    params = {}
    params[:project_name] = project_name
    params[:template_dir] = template_dir
    params[:template_url] = template_url
    puts params
    params
  end
end
