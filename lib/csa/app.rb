#!/usr/bin/env ruby

require "csa/version"
require "gli"
require "xcodeproj"
require "cli/ui"
require "date"
require "csa/ext/string"

class App
  def initialize(options)
    @name = options[:project_name].capitalize_first
    @template_url = options[:template_url]
    @use_default = options[:use_default]
  end

  def run
    validate_project_name
    setup_template
    setup_project
  end

  def validate_project_name
    raise "Name is required" unless @name
    raise "Project name cannot contain spaces" if @name =~ /\s/
    raise "Project name cannot begin with a '.'" if @name[0, 1] == "."
    raise "Project name should only contain numbers and letters" if @name =~ /[^a-zA-Z0-9]/
  end

  def setup_template
    remove_userdata
    clone_template
    get_template_info
  end

  def clone_template
    if Dir.exist?(Pathname("./#{@name}"))
      question = CLI::UI.fmt("{{green:Folder #{@name} already exists, overwrite? (y/n)}}")
      override = CLI::UI.ask(question, default: "n")
      if override.downcase == "y"
        puts CLI::UI.fmt("{{green:rm -rf ./#{@name}}}")
        system "rm -rf ./#{@name}"
      else
        exit(0)
      end
    end

    unless @template_url.empty?
      puts CLI::UI.fmt("{{green:git clone #{@template_url} #{@name}}}")
      system "git clone #{@template_url} #{@name}"
      system "rm -rf ./#{@name}/Pods"
    else
      exit(0)
    end
    remove_userdata
  end

  def remove_userdata
    system "rm -rf ./#{@name}/**/.git"
    system "rm -rf ./#{@name}/**/.DS_Store"
    system "rm -rf ./#{@name}/**/xcuserdata/"
    system "rm -rf ./#{@name}/**/**/xcuserdata/"
    system "rm -rf ./#{@name}/**/**/xcshareddata"
  end

  def get_template_info
    template_path = Dir.glob("./#{@name}/**/**/*.xcodeproj").first
    @template_name = File.basename(template_path, ".xcodeproj")
    @template_name_other = @template_name.gsub(/[^a-zA-Z0-9]/, "_")
    get_template_author_organization
  end

  def get_template_author_organization
    app_delegate_path = Dir.glob("./#{@name}/**/**/*AppDelegate*.swift").last
    raise "Can't find your AppDelegate file" if app_delegate_path.nil?

    @template_author = File.open(app_delegate_path) do |file|
      file.each_line do |line|
        break line if /^\/\/ {2}Created by/ =~ line
      end
    end

    index1 = @template_author.index("by") + 2
    index2 = @template_author.index("on")
    @template_author = @template_author[0, index2]
    @template_author = @template_author[index1, index2]
    @template_author.strip!

    @template_organization = File.open(app_delegate_path) do |file|
      file.each_line do |line|
        break line if /^\/\/ {2}Copyright ©/ =~ line
      end
    end

    index1 = @template_organization.index("©") + 1
    index2 = @template_organization.index(".")
    @template_organization = @template_organization[0, index2]
    @template_organization = @template_organization[index1, index2]
    @template_organization.strip!
  end

  def setup_project
    get_project_info
    rename_files
    set_bundle_identifiers
    add_git
    install_pods
    add_fastlane
    open_project
  end

  def get_project_info
    if @use_default
      @author = "AUTHOR"
      @organization = "ORG"
      return
    end

    # get author and org name
    question_author = CLI::UI.fmt("{{green:Author for the project:}}")
    question_orgname = CLI::UI.fmt("{{green:Organization Name for the project:}}")
    @author = CLI::UI.ask(question_author)
    @organization = CLI::UI.ask(question_orgname)
    @author.strip!
    @organization.strip!
    @author = "AUTHOR" if @author.empty?
    @organization = "ORG" if @organization.empty?
  end

  def rename_files(path = Pathname("./#{@name}"))
    puts "updating #{path}"
    path = rename(path)
    if File.directory?(path)
      Dir.each_child(path) do |file|
        rename_files(path + file)
      end
    else
      update_content(path)
    end
  end

  def rename(original_name)
    name_new = original_name.sub(Regexp.new(Regexp.escape(@template_name), Regexp::IGNORECASE), @name)
    name_new = name_new.sub(Regexp.new(Regexp.escape(@template_name_other), Regexp::IGNORECASE), @name)
    File.rename(original_name, name_new) if original_name != name_new
    name_new
  end

  def update_content(path)
    begin
      file = File.new("#{path}_new", "w+")
      origin = File.open(path, "r:UTF-8")
      today = Date.today.strftime("%d/%m/%y")
      origin.each do |line|
        line = "//  Created by #{@author} on #{today}." if /^\/\/ {2}Created by/ =~ line
        line = "//  Copyright © #{Time.new.strftime("%Y")} #{@organization}. All rights reserved." if /^\/\/ {2}Copyright ©/ =~ line
        line.gsub!(Regexp.new(Regexp.escape(@template_name), Regexp::IGNORECASE), @name)
        line.gsub!(Regexp.new(Regexp.escape(@template_name_other), Regexp::IGNORECASE), @name)
        line.gsub!(Regexp.new(Regexp.escape(@template_organization), Regexp::IGNORECASE), @organization)
        line.gsub!(Regexp.new(Regexp.escape(@template_author), Regexp::IGNORECASE), @author)
        file.puts line
      end
      origin.close
      file.close
      File.delete(origin)
      File.rename("#{path}_new", path)
    rescue Exception
      # ignored
    end
  end

  def set_bundle_identifiers
    project_path = Dir.glob("./#{@name}/**/**/#{@name}.xcodeproj").first
    project = Xcodeproj::Project.open(project_path)
    project.root_object.attributes["ORGANIZATIONNAME"] = @organization
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.#{@organization.downcase.gsub(/[^a-zA-Z0-9]/, "-")}.#{@name.downcase}"
      end
    end
    project.save
    return if @use_default

    # change bundle identifier
    puts CLI::UI.fmt("{{cyan:Let's setup your bundle identifiers}}")
    project.targets.each do |target|
      target.build_configurations.each do |config|
        original_bundle_identifier = config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"]
        question = CLI::UI.fmt("Bundle Identifier of Target {{green:#{target}}} for {{green:#{config}}}")
        answer = CLI::UI.ask(question, default: original_bundle_identifier)
        config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = answer if answer != original_bundle_identifier
      end
    end
    project.save
  end

  def add_git
    return if Dir.exist?(Pathname("./#{@name}/.git"))

    if @use_default
      Dir.chdir("#{@name}") do |_|
        system "git init > /dev/null"
        puts "Initialized empty Git repository in ./#{@name}/.git/"
      end
      return
    end

    question = CLI::UI.fmt("{{green:Do you want to use git?}} (y/n)")
    answer = CLI::UI.ask(question, default: "y")
    if answer.downcase == "y"
      Dir.chdir("#{@name}") do |_|
        system "git init > /dev/null"
        puts "Initialized empty Git repository in ./#{@name}/.git/"
        question = CLI::UI.fmt("{{green:Repository url for the project: (enter to skip)?}}")
        @repo_url = CLI::UI.ask(question)
        @repo_url.strip!
        unless @repo_url.empty?
          system "git remote add origin #{@repo_url}"
          system "git push --set-upstream origin master"
        end
      end
    end
  end

  def install_pods
    return unless system "which pod > /dev/null"
    Dir.chdir("#{@name}") do |_|
      if File.exists?("Podfile")
        if @use_default
          system "pod deintegrate"
          system "pod install"
          return
        end

        question = CLI::UI.fmt("{{green:Podfile detected, do you want to install pods now?}}")
        answer = CLI::UI.ask(question, options: %w(install skip))
        case answer
        when "install"
          system "pod deintegrate"
          system "pod install"
        else break
        end
      end
    end
  end

  def add_fastlane
    return unless system "which fastlane > /dev/null"
    return if @use_default
    question = CLI::UI.fmt("{{green:Do you want to add fastlane to your project?}} (y/n)")
    answer = CLI::UI.ask(question, default: "n")
    return unless answer == "y"
    Dir.chdir("#{@name}") do |_|
      system "fastlane init"
    end
  end

  def open_project
    begin
      Dir.chdir("#{@name}") do |_|
        system "open ."
      end
      project = Dir.glob("./**/**/#{@name}.xcworkspace").first
      project = Dir.glob("./**/**/#{@name}.xcodeproj").first if project.nil?
      system "open #{project}"
    rescue Exception
      # ignore
    end
  end
end
