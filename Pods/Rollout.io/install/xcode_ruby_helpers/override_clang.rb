#!/usr/bin/env ruby
require_relative './bundle/bundler/setup'

require 'xcodeproj'

class OverrideClang
  def initialize(initialized_project)
    @project = initialized_project
  end

  def uninstall
    installOrUninstall true
  end

  def installOrUninstall(uninstall, lib_path = nil)
    settings = {
      "CC" => "compiler/clang",
      "LD" => "linker/clang",
      "LDPLUSPLUS" => "linker/clang++",
      "LIPO" => "lipo/lipo"
    }
    @project.targets.each do |target| 
      if target.respond_to?("product_type") and target.product_type == "com.apple.product-type.application"
        target.build_configurations.each do |configuration|
	  build_settings = configuration.build_settings
	  settings.keys.each do |key|
	    if uninstall
	      build_settings.delete key
	    else
              build_settings[key] = "#{lib_path}/clang_wrapper/#{settings[key]}"
	    end
	  end
	end
      end
    end
  end
end
