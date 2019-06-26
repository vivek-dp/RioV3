rioload_ruby '/tools/UIInterface'
rioload_ruby '/tools/UtilitiesInterface'

module RIO
	module DevTools
		def self.load_menu_items
			extension_menu = UI.menu(%q(Extensions))
			extension_menu.add_item('Rio Dev Tools') {
				tools_inst = RIO::Tools::UITools.instance
				tools_inst.load_tools
			}
		end
		
		def self.load_utilities
			extension_menu = UI.menu(%q(Extensions))
			extension_menu.add_item('Rio Utilities') {
				tools_inst = RIO::Utilities::Helpers.instance
				tools_inst.load_tools
			}
		end
	end
end