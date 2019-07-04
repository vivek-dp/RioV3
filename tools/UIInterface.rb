require 'singleton'
require_relative '../features/CivilFeatures.rb'
require_relative '../core/CivilHelper.rb'
require_relative '../tools/UtilitiesInterface.rb'

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

			def create_room elements_a
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
			end

			def get_room_names
				
			end

			def check_room_face room_face
				no_layers_flag = true
				no_layer_edge_a = []
				room_face.edges.each { |face_edge|
					if face_edge.layer.name.start_with?('RIO')
						no_layers_flag = false
					else
						no_layer_edge_a << face_edge
					end
				}
				if no_layers_flag
					RIO::Utilities::ModalBox::no_layer_added
					return false
				elsif !no_layer_edge_a.empty?
					sel.clear
					sel.add(no_layer_edge_a)
					resp = UI.messagebox('Selected lines are not layered in this face. Shall we mark them as walls', MB_OKCANCEL)
					puts "resp : #{resp} : #{no_layer_edge_a}"
					if resp==1
						puts "Setting layers"
						no_layer_edge_a.each{|sel_edge|
							puts "edge : #{sel_edge}"
							sel_edge.layer=Sketchup.active_model.layers['RIO_Wall']
						}
					else
						return false
					end
				end
				return true
			end
			
			def create_dialog_room_addition
				# if @@rio_dialog && @@rio_dialog.visible?
				# 	puts "Dialog already open"
				# elsif @@rio_dialog && !@@rio_dialog.visible?
				# 	@@rio_dialog.show()
				# else
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
				
					@@rio_dialog.add_action_callback("rioCreateRoom"){|dialog, params|
						puts "Inside UI..   #{dialog} -- #{params}"
						elements_a = get_params_from_string params
						create_room(elements_a)
					}
					@@rio_dialog.add_action_callback("rioRemoveRoomComponents") {|dialog, params|
						RIO::CivilHelper.remove_room_entities(params)
					}
					@@rio_dialog.show()
				#end
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
			
			puts "sendWallLocation : #{inputs}"
			
			wall_selected = Sketchup.active_model.selection[0]
			unless wall_selected
				UI.messagebox "Nothing selected. Please select a wall."
				return false
			end
			
			block_type = wall_selected.get_attribute :rio_block_atts, 'block_type'
			unless block_type=='wall'
				UI.messagebox "Selection is not a wall"
				return false
			end
			
			towards_wall_v = wall_selected.get_attribute :rio_block_atts, 'towards_wall_vector' 
			
			#Get the wall vector			
			start_pt 	= wall_selected.get_attribute :rio_block_atts, 'start_point'
			end_pt 		= wall_selected.get_attribute :rio_block_atts, 'end_point'
			wall_vector = start_pt.vector_to(end_pt)
			
			wall_offset_point = RIO::CivilHelper::get_comp_location wall_selected, from_wall, from_floor , wall_side
			active_model = Sketchup.active_model

			active_model.set_attribute :rio_atts, 'room_name', wall_selected.get_attribute(:rio_block_atts, 'room_name')
			active_model.set_attribute :rio_atts, 'wall_offset_pt', wall_offset_point
			active_model.set_attribute :rio_atts, 'movement_vector', towards_wall_v
			active_model.set_attribute :rio_atts, 'wall_id', wall_selected.persistent_id
			active_model.set_attribute :rio_atts, 'wall_side', wall_side
			active_model.set_attribute :rio_atts, 'wall_vector', wall_vector
			active_model.set_attribute :rio_atts, 'wall_height', wall_selected.get_attribute(:rio_block_atts, 'wall_height')
			active_model.set_attribute :rio_atts, 'from_wall', from_wall
			active_model.set_attribute :rio_atts, 'from_floor', from_floor
			
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
		selected_entity = model.selection[0]
		rio_tools_inst = RIO::Tools::UITools.instance
		if selected_entity 
			case selected_entity
			when Sketchup::Face
				rbm = menu.add_submenu("Add RIO Comp-->")
				face_normal = selected_entity.normal
				if face_normal.parallel?(Z_AXIS)
					rbm.add_item("Room") { 
						resp = rio_tools_inst.check_room_face selected_entity
						if resp
							rio_tools_inst.create_dialog_room_addition
						end
					 }
					rbm.add_item("Column") {} 
				else
					rbm.add_item("Beam") { RIO::CivilHelper.create_beam(selected_entity) }
				end
			when Sketchup::Group
				puts "Group selected"
			when Sketchup::ComponentInstance
				comp_type = selected_entity.get_attribute(:rio_block_atts, 'block_type')
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