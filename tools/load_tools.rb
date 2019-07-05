rioload_ruby '/tools/UIInterface'
rioload_ruby '/tools/UtilitiesInterface'

module RIO
	module DevTools
		def self.load_menu_items
			extension_menu = UI.menu(%q(Extensions))
			extension_menu.add_item('Rio Dev Tools') {
				tools_inst = RIO::Tools::UITools.instance
				tools_inst.create_dialog_room_addition
			}
		end
		
		def self.load_utilities
			extension_menu = UI.menu(%q(Extensions))
			extension_menu.add_item('Rio Utilities') {
				tools_inst = RIO::Utilities::Helpers.instance
				tools_inst.load_tools
			}
		end

		def self.room_details
			extension_menu = UI.menu(%q(Extensions))
			extension_menu.add_item('Room Details') {
				tools_inst = RIO::Utilities::DeleteRooms.instance
				tools_inst.room_details
			}
		end
	end
end