#!/usr/bin/env ruby
require_relative './bundle/bundler/setup'

require 'xcodeproj'

class CreateScript
  def initialize(initialized_project)
    @project = initialized_project
  end

  def create_script(title, content, position)
    @project.targets.each do |source_target| 
      if source_target.respond_to?("product_type") and source_target.product_type == "com.apple.product-type.application"
        source_build_phase = source_target.source_build_phase
        build_phases = source_target.build_phases
    
        script_build_phase = @project.new(Xcodeproj::Project::Object::PBXShellScriptBuildPhase)
        script_build_phase.name = title
        script_build_phase.shell_script = content
      	if position == "before_linking"
          pre_index = build_phases.find_index { |b| b.display_name == "SourcesBuildPhase" }
      	elsif position == "end"
          pre_index = [
      	    build_phases.find_index { |b| b.display_name == "ResourcesBuildPhase" },
      	    build_phases.find_index { |b| b.display_name == "FrameworksBuildPhase" }
      	  ].max
        elsif position == "beginning"
          pre_index = -1
        else
          raise "Unknown position '#{position}'"
      	end
        build_phases.insert(pre_index + 1, script_build_phase) unless pre_index.nil?
      end
    end
  end
end
