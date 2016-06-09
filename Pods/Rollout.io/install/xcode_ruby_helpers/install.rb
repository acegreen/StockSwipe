#!/usr/bin/env ruby

require 'json'
require_relative './bundle/bundler/setup'
require_relative './remove_rollout_from_xcodeproj'
require_relative './addfile'
require_relative './create_script'
require_relative './override_clang'

def rgb(red, green, blue)
  16 + (red * 36) + (green * 6) + blue
end
def set_color(fg, bg)
  fg_string = fg ? "\x1b[38;5;#{fg}m" : ""
  bg_string = bg ? "\x1b[48;5;#{bg}m" : ""
  fg_string + bg_string
end
def reset_color
  "\x1b[0m"
end

configuration = JSON.parse(STDIN.read)
xcode_dir = configuration["xcode_dir"]
app_key = configuration["app_key"]
files_to_add = configuration["files_to_add"]
sdk_subdir = configuration["sdk_subdir"]
weak_system_frameworks = configuration["weak_system_frameworks"] || []

project = Xcodeproj::Project.new(xcode_dir)
project.initialize_from_file

prev_xcodeproj_version = RemoveRolloutFromXcodeproj.new(project).remove_rollout_from_xcodeproj
OverrideClang.new(project).uninstall

add_file = AddFile.new(project)
add_file_result = 0 
files_to_add.each do |full_path|
  add_file_result = [add_file.add_file(full_path), add_file_result].max
end
weak_system_frameworks.each do |framework|
  add_file.add_weak_system_framework(framework)
end

base_dir = File.dirname(File.dirname(File.dirname(File.absolute_path(__FILE__))))
xcodeproj_configuration=`. '#{base_dir}/lib/versions' ; /bin/echo -n $xcodeproj_configuration`

script_content = "ROLLOUT_lastXcodeprojConfiguration=#{xcodeproj_configuration} \"\${SRCROOT}/#{sdk_subdir}/lib/upload_dsym_phase\" -k #{app_key}"
CreateScript.new(project).create_script("Rollout.io dsym upload", script_content, "end")

project.save()

if prev_xcodeproj_version < 5
	c_none = reset_color()
	c_alert = set_color(rgb(5, 5, 5), rgb(3, 0, 0))
    c_instruction = set_color(rgb(0, 4, 4), nil)
    c_selector = set_color(rgb(0, 0, 4), nil)
    cc_black = set_color(rgb(0, 0, 0), rgb(5, 5, 5))
    cc_preprocessor = set_color(rgb(3, 2, 0), rgb(5, 5, 5))
    cc_string = set_color(rgb(4, 0, 0), rgb(5, 5, 5))
    cc_known = set_color(rgb(2, 3, 3), rgb(5, 5, 5))
    cc_reserved = set_color(rgb(5, 0, 4), rgb(5, 5, 5))

    begin
      width = `tput cols`.to_i()
    rescue Exception
      width = 80
    end
    cc_init_line = "#{cc_black}\x1b[s#{" " * width}\x1b[u"

	setup_call_snippet =\
      "#{cc_init_line}    [#{cc_known}Rollout setupWithKey#{cc_black}:#{cc_string}@\"#{app_key}\"\n" +
      "#{cc_init_line}#{cc_preprocessor}#ifdef DEBUG\n" +
      "#{cc_init_line}        #{cc_known}developmentDevice#{cc_black}:#{cc_reserved}YES\n" +
      "#{cc_init_line}#{cc_preprocessor}#endif\n" +
      "#{cc_init_line}    ];#{c_none}\n"

	if(prev_xcodeproj_version == 0)
	  puts(\
	  	"\n"\
	  	"#{c_alert}Please don't forget to add the following code to your AppDelegate:#{c_none}\n"\
	  	"\n"\
	  	"#{c_instruction}At the beginning of AppDelegate:#{c_none}\n"\
	  	"#{cc_init_line}#{cc_preprocessor}#import #{cc_string}<Rollout/Rollout.h>#{c_none}\n"\
	  	"\n"\
	  	"#{c_instruction}In the #{c_selector}application:didFinishLaunchingWithOptions:#{c_instruction} method:#{c_none}\n"\
	  	"#{setup_call_snippet}"\
	  	"\n"
	  )
	else
	  puts(\
	  	"\n"\
	  	"#{c_alert}This Rollout SDK upgrade requires a change in your AppDelegate call!#{c_none}\n"\
	  	"\n"\
	  	"#{c_instruction}Please change the call to Rollout setup in the #{c_selector}application:didFinishLaunchingWithOptions:#{c_instruction} method to the following:\n"\
	  	"#{setup_call_snippet}"\
	  	"\n"
	  )
	end

end

exit add_file_result
