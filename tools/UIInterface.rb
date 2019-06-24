require 'singleton'
require_relative '../features/CivilFeatures.rb'
module RIO
	module Tools
		class UITools
			include Singleton
			@@rio_dialog = nil
			
			def initialize
				@dialog_width = 400
				@dialog_height = 650
				@dialog_url = 'E:/V3/Working/tools/tools_main.html'
				@style_window = UI::HtmlDialog::STYLE_WINDOW
				@style_dialog = UI::HtmlDialog::STYLE_DIALOG
			end
			
			def load_tools
				dialog_hash = {}
				dialog_hash[:dialog_title] 	= 'Rio Dev Tools'
				dialog_hash[:scrollable]	= true
				dialog_hash[:resizable]		= true
				dialog_hash[:width]			= @dialog_width
				dialog_hash[:height]		= @dialog_height
				dialog_hash[:min_width]		= 50
				dialog_hash[:min_height]	= 50
				dialog_hash[:style]			= @style_dialog
				dialog_hash[:left]			= 100
				dialog_hash[:right]			= 100
				
				@@rio_dialog = UI::HtmlDialog.new(dialog_hash)
				@@rio_dialog.set_url(@dialog_url)
				@@rio_dialog.show()
				
				@@rio_dialog.add_action_callback("rioCreateRoom"){|dialog, params|
					puts "Inside UI rioCreateRoom  ++#{params}++"
					ob = RIO::CivilMod::PolyRoom.new(  :room_name=>'rnam1',
                            :wall_height=>3000.mm, 
                            :wall_color=>'blue',
                            :door_height=>2000.mm, 
                            :window_height=>800.mm, 
                            :window_offset=>1000.mm) 
				}
				# @@rio_dialog.set_on_close { 
				# 	@@rio_dialog = nil
				# }
			end
		end
	end
end