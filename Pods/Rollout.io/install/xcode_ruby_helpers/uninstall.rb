#!/usr/bin/env ruby

require_relative './remove_rollout_from_xcodeproj'
require_relative './override_clang'

xcode_dir = ARGV[0]

project = Xcodeproj::Project.new(xcode_dir)
project.initialize_from_file

RemoveRolloutFromXcodeproj.new(project).remove_rollout_from_xcodeproj
OverrideClang.new(project).uninstall

project.save()