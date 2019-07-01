require 'singleton'
require_relative '../features/CivilFeatures.rb'
require_relative '../core/CivilHelper.rb'
module RIO
	module Tools
		class UITools
			include Singleton
			@@rio_dialog = nil
			
			def initialize
				@dialog_width 	= 400
				@dialog_height 	= 650
				@dialog_url 	= RIO_ROOT_PATH + 'tools/tools_main.html'
				@style_window 	= UI::HtmlDialog::STYLE_WINDOW
				@style_dialog 	= UI::HtmlDialog::STYLE_DIALOG
			end
			
			def get_params_from_string param_str
				#Benchmark fast
				param_str = param_str[2..-2]
				elements_a = param_str.split('"@"')
				elements_a
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
					puts "Inside UI..   #{dialog} -- #{params}"
					elements_a = get_params_from_string params
					room_name 		= elements_a[0]
					wall_height 	= elements_a[1].to_f.mm
					door_height 	= elements_a[2].to_f.mm
					window_height	= elements_a[3].to_f.mm
					window_offset	= elements_a[4].to_f.mm 

					ob = RIO::CivilMod::PolyRoom.new(  :room_name=>room_name,
						:wall_height=>wall_height, 
						:door_height=>door_height,
						:window_height=>window_height, 
						:window_offset=>window_offset)
							
						# ob = RIO::CivilMod::PolyRoom.new(  :room_name=>'rnam1',
                        #     :wall_height=>3000.mm, 
                        #     :wall_color=>'blue',
                        #     :door_height=>2000.mm, 
                        #     :window_height=>800.mm, 
                        #     :window_offset=>1000.mm) 
				}
				@@rio_dialog.add_action_callback("rioRemoveRoomComponents") {|dialog, params|
					RIO::CivilHelper.remove_room_entities(params)
				}
				
			end
		end
	end #module Tools

	def self.get_wall_location
		dialog_url 		= RIO_ROOT_PATH + 'tools/wall_location.html' 
		dialog_inputs_h = { :title		=>'Enter wall location',
							:scrollable	=>false,
							:resizable	=>false,
							:width 		=>400,
							:height		=>600
							#:style		=>UI::HtmlDialog::STYLE_DIALOG
						}
		wall_location_dialog = UI::HtmlDialog.new(dialog_inputs_h)
		wall_location_dialog.add_action_callback("sendWallLocation") { |dialog, params|
			inputs = params.split(',')
			from_wall 	= inputs[0].to_f.mm
			wall_side 	= inputs[1]
			from_floor 	= inputs[2].to_f.mm
			
			wall_selected = Sketchup.active_model.selection[0]
			towards_wall_v = wall_selected.get_attribute :rio_block_atts, 'towards_wall_vector' 
			
			#Get the wall vector			
			start_pt 	= wall_selected.get_attribute :rio_block_atts, 'start_point'
			end_pt 		= wall_selected.get_attribute :rio_block_atts, 'end_point'
			wall_vector = start_pt.vector_to(end_pt)
			
			wall_offset_point = RIO::CivilHelper::get_comp_location wall_selected, from_wall, from_floor , wall_side
			active_model = Sketchup.active_model
			active_model.set_attribute :rio_atts, 'wall_offset_pt', wall_offset_point
			active_model.set_attribute :rio_atts, 'movement_vector', towards_wall_v
			active_model.set_attribute :rio_atts, 'wall_id', wall_selected.persistent_id
			active_model.set_attribute :rio_atts, 'wall_side', wall_side
			active_model.set_attribute :rio_atts, 'wall_vector', wall_vector
			
			$rio_wall_trans = wall_selected.transformation
			
			puts "The start point is : #{from_wall} : #{from_floor} : #{wall_offset_point}"
			
			if true #only for the civil 
				carcass_path 	= File.join(RIO_ROOT_PATH, 'assets/BC_800.skp')
				defn 			= Sketchup.active_model.definitions.load(carcass_path)
				
				RIO::CivilHelper::place_component defn, 'wall'
			end
		}
		wall_location_dialog.set_url(dialog_url);
		wall_location_dialog.show();
	end
	
	UI.add_context_menu_handler do |menu|
		model = Sketchup.active_model
		selection = model.selection[0]
		if selection 
			case selection
			when Sketchup::Face
				# rbm = menu.add_submenu("Add RIO")
				
				# rbm.add_item("Column"){ puts "column"}
				# rbm.add_item("Beam") { RIO::CivilHelper.create_beam(selection) }
			when Sketchup::Group
				puts "Group selected"
			when Sketchup::ComponentInstance
				comp_type = selection.get_attribute(:rio_block_atts, 'block_type')
				puts "Comp type : #{comp_type}"	
				case comp_type
				when 'wall'
					menu.add_item("Fix Rio Component") {
						get_wall_location
					}
				else
				end
			end
		end
	end
end