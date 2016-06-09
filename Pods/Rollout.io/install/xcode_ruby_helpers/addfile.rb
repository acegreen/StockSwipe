#!/usr/bin/env ruby

require_relative './bundle/bundler/setup'
require 'xcodeproj'
  
class AddFile
  def initialize(initialized_project)
    @project = initialized_project
  end

  def add_file(full_path)
    parent = find_or_create_rollout
    existing_file = find_file_in_directory(parent, full_path)
    if existing_file
      puts "File already exists in project, doing nothing"
      return 1
    end
    file = parent.new_file(full_path)
    puts "adding file #{full_path}"
    ext = File.extname(full_path)
    if [".m"].include? ext
      puts "adding build file for #{full_path}"
      buildFile = @project.new(Xcodeproj::Project::PBXBuildFile)
      buildFile.file_ref = file
      buildFile.settings = {COMPILER_FLAGS: "-fobjc-arc"}
      @project.targets.each do |t| 
        t.source_build_phase.files << buildFile if t.respond_to?("product_type") and t.product_type == "com.apple.product-type.application"
      end
      return 0
    end
    if [".framework"].include? ext
        puts "adding build file for Framework #{full_path}"
        buildFile = @project.new(Xcodeproj::Project::PBXBuildFile)
        buildFile.file_ref = file
        @project.targets.each do |t| 
          t.frameworks_build_phase.files << buildFile if  t.respond_to?("product_type") and t.product_type == "com.apple.product-type.application"
          t.build_configurations.each do |c|
            framework_search_path = c.build_settings["FRAMEWORK_SEARCH_PATHS"]
	    if(framework_search_path.nil?)
              framework_search_path = c.build_settings["FRAMEWORK_SEARCH_PATHS"] = []
	    end

	    inherited="$(inherited)"
	    framework_search_path << inherited unless framework_search_path.include? inherited

            framework_search_path << File.dirname(full_path)
          end
        end
        return 0
    end
    if [".h"].include?  ext
      #Do nothing 
      return 0
    end 
    if [".xib", ".storyboard", ".png", ".plist"].include?  ext
      puts "adding nib file #{full_path} to resources_build_phase"
      buildFile = @project.new(Xcodeproj::Project::PBXBuildFile)
      buildFile.file_ref = file
      @project.targets.each do |t| 
        t.resources_build_phase.files << buildFile if  t.respond_to?("product_type") and t.product_type == "com.apple.product-type.application"
      end
      return 0
    end
    puts "not sure what to do with beside adding #{full_path}"
    return 0
  end

  def add_weak_system_framework(framework)
    group = @project.frameworks_group
    ref = group.find_file_by_path(framework) || group.new_file(framework, :sdk_root) 
    frameworks = @project.frameworks_group
    @project.targets.select{|t| t.respond_to?("product_type") and t.product_type == "com.apple.product-type.application"}.each do |target| 
      build_file = target.frameworks_build_phase.build_file(frameworks.files.find { |f| f.path == framework }) || target.frameworks_build_phase.add_file_reference(ref)
      build_file.settings ||= {}
      build_file.settings['ATTRIBUTES'] = ['Weak']
    end
  end
  
  def find_or_create_rollout
    folder = "Rollout"
    found = @project.objects.find { |o| o.isa == "PBXGroup" && (o.path == folder || o.name == folder) }
    found.nil? ? @project.new_group(folder) : found
  end
  
  def find_file_in_directory(parent, full_path)
    parent.files.find {|f| f.path == full_path } 
  end
  
end
