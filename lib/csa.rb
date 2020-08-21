#!/usr/bin/env ruby

require "csa/version"
require "gli"
require "xcodeproj"
require "cli/ui"
require "date"

class App
  def initialize(name, template_url)
    @name = name
    @template_url = template_url
  end

  def run
    validate_project_name
    setup_template
    setup_project
  end

  def validate_project_name
    raise CLI::UI.fmt("{{red: Name is required}}") unless @name
    raise CLI::UI.fmt("{{red: Project name cannot contain spaces}}") if @name =~ /\s/
    raise CLI::UI.fmt("{{red: Project name cannot begin with a '.'}}") if @name[0, 1] == "."
    raise CLI::UI.fmt("{{red: Project name should only contain numbers and letters}}") if @name =~ /[^a-zA-Z0-9]/
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
        puts CLI::UI.fmt("removing #{@name}")
        system "rm -rf ./#{@name}"
      else
        exit(0)
      end
    end
    system "git clone #{@template_url} #{@name}"
    remove_userdata
  end

  def remove_userdata
    system "rm -rf ./**/.git"
    system "rm -rf ./**/.DS_Store"
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
    question_author = CLI::UI.fmt("{{green:Author for the project:}}")
    question_orgname = CLI::UI.fmt("{{green:Organization Name for the project:}}")
    @author = CLI::UI.ask(question_author)
    @organization = CLI::UI.ask(question_orgname)
    @author.strip!
    @organization.strip!
    @author = "AUTHOR" if @author.empty?
    @organization = "ORG NAME" if @organization.empty?
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
      origin.each do |line|
        line = "//  Created by #{@author} on #{Date.today}." if /^\/\/ {2}Created by/ =~ line
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
    puts CLI::UI.fmt("{{cyan:Let's setup your bundle identifiers}}")
    project_path = Dir.glob("./#{@name}/**/**/#{@name}.xcodeproj").first
    project = Xcodeproj::Project.open(project_path)
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.#{@organization.downcase.gsub(/[^a-zA-Z0-9]/, "_")}.#{@name}"
      end
    end
    project.save
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
    return nil if Dir.exist?(Pathname("./#{@name}/.git"))

    question = CLI::UI.fmt("{{green:Do you want to use git?}} (y/n)")
    answer = CLI::UI.ask(question, default: "y")
    if answer.downcase == "y"
      Dir.chdir("#{@name}") do |_|
        system "git init > /dev/null"
        puts "Git has been Initialized"
        question = CLI::UI.fmt("{{green:Repository url for the project: (enter to skip)?}}")
        @repo_url = CLI::UI.ask(question)
        @repo_url.strip!
        system "git remote add origin #{@repo_url}" unless @repo_url.empty?
      end
    end
  end

  def install_pods
    return nil unless system "which pod > /dev/null"
    Dir.chdir("#{@name}") do |_|
      if File.exists?("Podfile")
        question = CLI::UI.fmt("{{green:Podfile detected, do you want to install pods now}}?")
        answer = CLI::UI.ask(question, options: %w(install skip))
        case answer
        when "install"
          system "pod install"
        else break
        end
      end
    end
  end

  def add_fastlane
    return nil unless system "which fastlane > /dev/null"
    question = CLI::UI.fmt("{{green:Do you want to add fastlane to your project? (y/n)}}?")
    answer = CLI::UI.ask(question, default: "y")
    return nil unless answer == "y"
    Dir.chdir("#{@name}") do |_|
      system "fastlane init"
    end
  end

  def open_project
    project = Dir.glob("./**/**/#{@name}.xcworkspace").first
    project = Dir.glob("./**/**/#{@name}.xcodeproj") unless Dir.glob(project).any?
    system "open #{project}"
    Dir.chdir("#{@name}") do |_|
      system "open ."
    end
  end
end

# ============== MAIN ==============
raise CLI::UI.fmt("{{red:Git is required}}") unless system "which git > /dev/null"
if ARGV.length >= 0
  project_name = ARGV[0] ? ARGV[0] : "Demo"
  template_url = ARGV[1] ? ARGV[1] : "https://github.com/dianyij/swift-template.git"
  app = App.new(project_name, template_url)
  app.run
end
