# All the Helper functions for the wall building block should be written here.
#

WALL_HEIGHT = 3000.mm

def t2
	load 'E:\V3\Working\testing\wall_helper.rb'
	#get_wall_points
end

#
def check_room_outer_edges input_face
    if !selected_face.is_a?(Sketchup::Face) 
        puts "Input is not a face"
        return false
    end
    allowed_layers = ['RIO_Wall', 'RIO_Window', 'RIO_Door', 'RIO_Column']
    sel_edges = []
    input_face.edges.each { |face_edge|
        sel_edges << face_edge unless allowed_layers.include?(face_edge.layer.name)
    }
    unless sel_edges.empty?
        sel_a = Sketchup.active_model.selection
        sel_a.clear
        sel_a.add(sel_edges)
        UI.messagebox("The selected lines should have a proper layer name")
    end
end

def get_comp_pid id
	Sketchup.active_model.entities.each{|x| return x if x.persistent_id == id};
	return nil;
end

def add_wall_corner_lines
	model 	= Sketchup.active_model
	pts = []
	wall_faces = []
	all_faces = Sketchup.active_model.entities.grep(Sketchup::Face)


	all_faces.each{|face|
		wall_face_flag = true
		face.edges.each{|edge|
			wall_face_flag = false if edge.layer.name != 'RIO_Wall'
		}
		wall_faces << face if wall_face_flag
	}
	
	wall_layer = Sketchup.active_model.layers['RIO_Wall']
	
	#puts "wall_faces : #{wall_faces}"
	if false
		wall_faces.each {|face|
			face.edges.each{ |edge|
				verts =  edge.vertices
				verts.each{ |vert|
					other_vert = verts - [vert]
					other_vert = other_vert[0]
					#puts "vert : #{vert} : #{other_vert} : #{verts}"
					
					vector 	= vert.position.vector_to(other_vert).reverse
					pt 		= vert.position.offset vector, 10.mm
					res 	= face.classify_point(pt)
					#puts "res : #{res} : #{edge} "
					if res == Sketchup::Face::PointInside || res == Sketchup::Face::PointOnFace
						ray = [vert.position, vector]
						hit_item 	= model.raytest(ray, false)
						puts hit_item, hit_item[1][0].layer
						if hit_item[1][0].layer.name == 'RIO_Wall'
							#puts "Wall..."
							pts << [vert.position, hit_item[0]]
						end
					end
				}
			}
		}
		pts.flatten!.uniq!
		pts.each { |pt|
			zpt = pt.clone; zpt.z=1000
			#puts "pt : #{pt} : #{zpt}"
			Sketchup.active_model.entities.add_cline(pt, zpt)
		}
		pts
	end


	#Add corner lines
	if true
		#Latest one...based on wall distance
		wall_faces.each { |wall_face|
			wall_face.outer_loop.edges.each{ |edge|
				verts 	= edge.vertices

				first_vert 		= verts[0]
				second_vert 	= verts[1]

				ray_vector 	= first_vert.position.vector_to second_vert.position

				start_pt	= first_vert.position

				ray = [start_pt, ray_vector.reverse]
				hit_item = Sketchup.active_model.raytest(ray, false)
				#tputs "hit_item : #{hit_item}"

				if hit_item && hit_item[1][0].is_a?(Sketchup::Edge)
					if hit_item[1][0].layer.name == 'RIO_Wall'
						distance = first_vert.position.distance hit_item[0]
						#puts distance
						if distance < 251.mm
							wall_line = Sketchup.active_model.entities.add_line first_vert.position, hit_item[0]
							wall_line.layer = wall_layer
						end
					end
				end


				start_pt	= second_vert.position

				ray = [start_pt, ray_vector]
				hit_item = Sketchup.active_model.raytest(ray, false)
				puts "hit_item : #{hit_item}"

				if hit_item && hit_item[1][0].is_a?(Sketchup::Edge)
					if hit_item[1][0].layer.name == 'RIO_Wall'
						distance = second_vert.position.distance hit_item[0]
						#puts distance
						if distance < 251.mm
							#puts "Draw line......."
							wall_line = Sketchup.active_model.entities.add_line second_vert.position, hit_item[0]
							wall_line.layer = wall_layer
						end
					end
				end
			}
		}
		
	end
	
	
end

def get_outer_walls
	outer_layers = ['RIO_Wall', 'RIO_Window']
	wall_edges 	= Sketchup.active_model.entities.grep(Sketchup::Edge).select{|edge| outer_layers.include?(edge.layer.name)} 
	walls 		= wall_edges.select{|x| x.faces.length == 1}
	walls
end

def find_edge_face_vector edge, face
	return false if edge.nil? || face.nil?
	edge_vector = edge.line[1]
	perp_vector = Geom::Vector3d.new(edge_vector.y, -edge_vector.x, edge_vector.z)
	offset_pt 	= edge.bounds.center.offset(perp_vector, 2.mm)
	res = face.classify_point(offset_pt)
	return perp_vector if (res == Sketchup::Face::PointInside||res == Sketchup::Face::PointOnFace)
	return perp_vector.reverse
end

def perimeter_wall
	outer_walls = get_outer_walls
	wall_width 	= 30.mm 
	outer_walls.each { |wall_edge|
		verts = wall_edge.vertices
		
		clockwise = check_clockwise_edge wall_edge, wall_edge.faces[0]
		if clockwise
			pt1, pt2 = verts[0].position, verts[1].position
		else
			pt1, pt2 = verts[1].position, verts[0].position
		end
		if wall_edge.layer.name == 'RIO_Wall'
			create_wall_instance(pt2, pt1, wall_height: WALL_HEIGHT, wall_width: wall_width)
		elsif wall_edge.layer.name == 'RIO_Window'
			#create_window window_edge, room_face, window_height, window_offset, wall_height
		end
	}
end

def check_clockwise_edge edge, face
	#Temp code
	edge, face = face, edge if edge.is_a?(Sketchup::Face)
	
	conn_vector = find_edge_face_vector(edge, face)
	dot_vector	= conn_vector * edge.line[1]
	
	clockwise = dot_vector.z > 0
	if clockwise
		#puts "Clockwise"
	else
		#puts "Anti clockwise"
	end
	return clockwise
end

def create_room room_face, room_name='room_1'
	return "No value sent" unless room_face
	return "Please select a face" unless room_face.is_a?(Sketchup::Face) 
	
	wall_width 		= 50.mm
	window_height 	= 700.mm
	window_offset	= 1000.mm
	wall_height 	= WALL_HEIGHT 
	door_height		= 2000.mm
	
	room_wall_edges = room_face.edges.select{|edge| edge.layer.name == 'RIO_Wall'} 
	room_wall_edges.select{|e| e.layer.name == 'RIO_Wall'}.each{ |wall_edge|
		verts = wall_edge.vertices
		
		clockwise = check_clockwise_edge wall_edge, room_face
		if clockwise
			pt1, pt2 = verts[0].position, verts[1].position
		else
			pt1, pt2 = verts[1].position, verts[0].position
		end
		
		towards_wall_vector = check_edge_vector wall_edge, room_face
		
		wall_inst = create_wall_instance(pt1, pt2, wall_height: wall_height)
		wall_inst.set_attribute(:rio_block_atts, 'wall_block', 'true')
		wall_inst.set_attribute(:rio_block_atts, 'start_point', pt1)
		wall_inst.set_attribute(:rio_block_atts, 'end_point', pt2)
		wall_inst.set_attribute(:rio_block_atts, 'wall_height', wall_height)
		wall_inst.set_attribute(:rio_block_atts, 'room_name', room_name)
		wall_inst.set_attribute(:rio_block_atts, 'towards_wall_vector', towards_wall_vector) #Will used for beam
	}
	puts "Room Walls created..."
	
	#------------------------------------------
	room_face.edges.select{|e| e.layer.name == 'RIO_Door'}.each{ |door_edge|
		puts "Door : #{door_edge}"
		create_door door_edge, room_face, door_height, wall_height
	}
	puts "Room Doors created"
	
	#------------------------------------------
	room_face.edges.select{|e| e.layer.name == 'RIO_Window'}.each{ |window_edge|
		puts "Window : #{window_edge}"
		create_window window_edge, room_face, window_height, window_offset, wall_height
	}
	puts "Room Windows created"
	
	#------------------------------------------
	create_columns room_face
	puts "Columns created"
end

def create_wall_instance( start_point, end_point, 
						wall_width: 50.mm, 
						wall_height: 2000.mm, 
						at_height: 0.mm)
	
	start_point = start_point.position if start_point.is_a?(Sketchup::Vertex)
	end_point = end_point.position if end_point.is_a?(Sketchup::Vertex)
	
	#puts "create_wall_instance params : #{method(__method__).parameters}"

	length 			= start_point.distance(end_point).mm
	
	#create 
	wall_defn 		= create_entity length, wall_width, wall_height
	
	#Add instance
	inst = Sketchup.active_model.entities.add_instance wall_defn, start_point
	
	extra = 0
	#Rotate instance
	trans_vector = start_point.vector_to(end_point)
	if trans_vector.y < 0
		trans_vector.reverse! 
		extra = Math::PI
	end
	angle 	= extra + X_AXIS.angle_between(trans_vector)
	inst.transform!(Geom::Transformation.rotation(start_point, Z_AXIS, angle))
	
	if at_height > 0.mm
		inst.transform!(Geom::Transformation.new([0,0,at_height]))
	end
	
	#For developments
	color = Sketchup::Color.names[rand(140)]
	inst.material = color
	
	inst.set_attribute :rio_atts, 'wall_block', 'true'
	inst
end

def get_current_entities
	Sketchup.active_model.entities.to_a
end

def create_entity length, width, height
	defn_name = 'rio_temp_defn_' + Time.now.strftime("%T%m")

	model		= Sketchup.active_model
	entities 	= model.entities
	defns		= model.definitions
	comp_defn	= defns.add defn_name
	
	pt1 		= ORIGIN
	pt2			= ORIGIN.offset(Y_AXIS, width)
	pt3 		= pt2.offset(X_AXIS, length.to_mm)
	pt4 		= pt1.offset(X_AXIS, length.to_mm)
	
	wall_temp_group 	= comp_defn.entities.add_group
	wall_temp_face 		= wall_temp_group.entities.add_face(pt1, pt2, pt3, pt4)
	
	ent_list1 	= get_current_entities
	wall_temp_face.pushpull -height
	ent_list2 	= get_current_entities
	
	new_entities 	= ent_list2 - ent_list1
	new_entities.grep(Sketchup::Face).each { |tface|
		wall_temp_group.entities.add_face tface
	}
	comp_defn
end

def create_door door_edge, room_face, door_height, wall_height


	room_edges 		= room_face.edges
	adjacent_edges 	= []
	
	if door_height > wall_height
		puts "Door height cannot be greater than wall height : #{door_height} : #{wall_height}"
		return 
	end
	
	#Find the adjacent perpendicular edges...90 degrees not 180,270
	room_edges.each{|redge|
		#puts "redge : #{redge}"
		unless (redge.vertices&door_edge.vertices).empty?
			angle = door_edge.line[1].angle_between redge.line[1]
			#puts "angle : #{angle}"
			adjacent_edges << redge if(angle.ceil(2)==(Math::PI/2).ceil(2))
		end
	}
	if adjacent_edges.empty? 
		puts "Door Wall Error: No Perpendicular Adjacent edges found"
		return
	end
	#----------------------------------------------------------------
	
	#Find edges less than 251 mm...greater than check not added now....
	adjacent_edges.select!{|ad_edge| ad_edge.length < 251.mm}
	if adjacent_edges.empty? 
		puts "Door Wall Error : Perpendicular edges are longer than 251mm"
		return
	else
		puts "adjacent_edges : #{adjacent_edges}"
		adjacent_edges.each{|adj_edge| adj_edge.set_attribute(:rio_atts, 'door_adjacent', door_edge.persistent_id)}
	end
	
	#Sort the length...descending 
	adjacent_edges.sort_by!{|ad_edge| -ad_edge.length}
	adjacent_edge = adjacent_edges[0]
	verts = door_edge.vertices
	entity_width = adjacent_edge.length
	
	clockwise = check_clockwise_edge door_edge, room_face
	if clockwise
		pt1, pt2 = verts[0].position, verts[1].position
	else
		pt1, pt2 = verts[1].position, verts[0].position
	end
	
	door_block_height = wall_height - door_height
	create_wall_instance(pt2, pt1, wall_width: entity_width, wall_height: door_block_height,at_height: door_height)
	
	add_real_door = true
	if add_real_door
		puts "add_real_door"
		door_skp = RIO_ROOT_PATH+'/assets/samples/Door.skp'
		door_defn = Sketchup.active_model.definitions.load(door_skp)
		
		inst 		= Sketchup.active_model.entities.add_instance door_defn, ORIGIN
		door_bbox 	= inst.bounds
		
		x_factor 	= door_edge.length / door_bbox.width
		y_factor 	= entity_width / door_bbox.height 
		z_factor	= door_height / door_bbox.depth 
		
		puts "factors : #{x_factor} : #{y_factor} : #{z_factor}"
		inst.transform!(Geom::Transformation.scaling(x_factor, y_factor, z_factor))
		
		
		inst.transform!(Geom::Transformation.new(pt2))
		extra = 0
		#Rotate instance
		trans_vector = pt2.vector_to(pt1)
		if trans_vector.y < 0
			trans_vector.reverse! 
			extra = Math::PI
		end
		angle 	= extra + X_AXIS.angle_between(trans_vector)
		puts "door angle : #{angle} : #{trans_vector}"
		inst.transform!(Geom::Transformation.rotation(pt2, Z_AXIS, angle))
	end
end



def create_window window_edge, room_face, window_height, window_offset, wall_height
	room_edges = room_face.edges
    verts      = window_edge.vertices
    
	adjacent_edges = []
	
	if (window_height+window_offset) > wall_height
		puts "Window height hits the roof : H - #{window_height} : O - #{window_offset} WH - #{wall_height}"
		return 
	end

	clockwise = check_clockwise_edge window_edge, room_face
	if clockwise
		pt1, pt2 = verts[0].position, verts[1].position
	else
		pt1, pt2 = verts[1].position, verts[0].position
	end
	
	top_wall_at_height 		= (window_height + window_offset) 
	top_wall_block_height 	= wall_height -  top_wall_at_height
	
	create_wall_instance(pt1, pt2, wall_height: window_offset)
	create_wall_instance(pt1, pt2, wall_height: top_wall_block_height, at_height: top_wall_at_height)
	
		
	add_real_window = true
	if add_real_window
		puts "add_real_door"
		window_skp = RIO_ROOT_PATH+'/assets/samples/Window.skp'
		window_defn = Sketchup.active_model.definitions.load(window_skp)
		
		inst 		= Sketchup.active_model.entities.add_instance window_defn, ORIGIN
		window_bbox 	= inst.bounds
		
		x_factor 	= window_edge.length / window_bbox.width
		y_factor 	= 50.mm / window_bbox.height 
		z_factor	= window_height / window_bbox.depth 
		
		puts "factors : #{x_factor} : #{y_factor} : #{z_factor}"
		inst.transform!(Geom::Transformation.scaling(x_factor, y_factor, z_factor))
		
		wpt1, wpt2 = pt1, pt2
		wpt1.z	=	window_offset
		wpt2.z 	= 	window_offset
		inst.transform!(Geom::Transformation.new(wpt1))
		extra = 0
		#Rotate instance
		trans_vector = wpt1.vector_to(wpt2)
		if trans_vector.y < 0
			trans_vector.reverse! 
			extra = Math::PI
		end
		angle 	= extra + X_AXIS.angle_between(trans_vector)
		puts "Window angle : #{angle} : #{trans_vector}"
		inst.transform!(Geom::Transformation.rotation(wpt1, Z_AXIS, angle))
	end
	
	#Check if the window is an external window
	create_external_window = false
	if create_external_window
		window_face 	= window_edge.faces
		window_face.delete room_face
		if window_face.one?
			window_face = window_face[0]
			window_face_arr = find_adj_window_face [window_face]
			external_face = window_face_arr.last
			external_edge = external_face.edges.select{|ed| ed.faces.length == 1}[0]
			if external_edge.layer.name == 'RIO_Window'
				puts "Its an external window. Adding the wall for the external edge."
				clockwise 	= check_clockwise_edge external_edge, external_face
				verts 		= external_edge.vertices
				if clockwise
					pt1, pt2 = verts[0].position, verts[1].position
				else
					pt1, pt2 = verts[1].position, verts[0].position
				end
				
				create_wall_instance(pt2, pt1, wall_height: window_offset)
				create_wall_instance(pt2, pt1, wall_height: top_wall_block_height, at_height: top_wall_at_height)
			else
				puts "One external edge found. But its layer is not window layer"
			end
		else
			puts "Window is not a proper external window"
		end
	end

end

def find_adj_window_face arr=[]
    face = arr.last
    face.edges.each{|edge|
        edge.faces.each{|face|
            window_edges = face.edges.select{|face_edge| face_edge.layer.name=='RIO_Window'}
            # puts window_edges.count
            if window_edges.count > 1 && !arr.include?(face)
                if face.edges.count == 4
                  arr.push(face)
                  find_adj_window_face arr
                end
            end
        }
    }
    return arr 
end

def delete_blocks
	inst_arr	= Sketchup.active_model.entities.grep(Sketchup::ComponentInstance)
	block_ents 	= inst_arr.select{|ent| ent.definition.name.start_with?('rio_temp_defn_')}
	puts "#{block_ents.length} will be deleted"
	Sketchup.active_model.entities.erase_entities block_ents
end

def get_room_blocks room_face

end

def add_real_wall door_edge, room_face
	verts = door_edge.vertices
	clockwise = check_clockwise_edge door_edge, room_face
	if clockwise
		pt1, pt2 = verts[1].position, verts[0].position
	else
		pt1, pt2 = verts[0].position, verts[1].position
	end

	extra = 0
	#Rotate instance
	trans_vector = pt1.vector_to(pt2)
	if trans_vector.y < 0
		trans_vector.reverse! 
		extra = Math::PI
	end
	angle 	= extra + X_AXIS.angle_between(trans_vector)
	inst.transform!(Geom::Transformation.rotation(pt1, Z_AXIS, angle))
end

def scale_component component_instance
	absolute_scale = [80, 70, 60]
	bounds = component_instance.bounds
	scale_factors = [bounds.width, bounds.height, bounds.depth].zip(absolute_scale).map{ |old, new| new / old }
	scale_transformation = Geom::Transformation.scaling(*scale_factors)
	component_instance.transform!(scale_transformation)
end


def create_columns input_face
    #input_face = fsel
	puts "Input face : #{input_face}"
	wall_height = -3000.mm
	
	Sketchup.active_model.layers.add('RIO_Civil_Column') if Sketchup.active_model.layers['RIO_Civil_Column'].nil?
	
	#Working on the outer loop of the floor....
	outer_loop_flag = true
	if outer_loop_flag
		face_edges = input_face.outer_loop.edges
		wall_layers = ['RIO_Wall', 'RIO_Window', 'RIO_Door']
		face_edges.length.times do
			f_edge = face_edges[0]
			break if f_edge.layer.name != 'RIO_Column'
			face_edges.rotate!
		end

		columns = []
		column_edges = []
		face_edges.each{ |f_edge|
			if f_edge.layer.name == 'RIO_Column'
				column_edges << f_edge
			else 
				columns << column_edges unless column_edges.empty?
				column_edges = []
			end
		}
		
		
		columns.each { |column_edge_arr|
			intersect_pt 	= nil
			column_face		= nil
			
			case column_edge_arr.length
			when 1 
				#Corner column with only one edge visible 
				column_edge = column_edge_arr[0]
				adjacent_edges = find_edges(column_edge_arr[0], input_face)
				intersect_pt = Geom.intersect_line_line(adjacent_edges[0].line, adjacent_edges[1].line)
				col_verts = column_edge.vertices
				column_face = Sketchup.active_model.entities.add_face(col_verts[0], col_verts[1], intersect_pt)
			when 2
				adjacent_edges = []
				column_edge_arr.each { |column_edge|
					adjacent_edges << find_edges(column_edge, input_face)
				}
				#puts "adj : #{adjacent_edges}"
				adjacent_edges.flatten!; adjacent_edges.uniq!
				
				intersect_pt = Geom.intersect_line_line(adjacent_edges[0].line, adjacent_edges[1].line)
				
				vert_a = []
				vert_a << column_edge_arr[1].vertices - column_edge_arr[0].vertices
				vert_a << column_edge_arr[0].vertices
				vert_a.flatten!; vert_a.uniq!
				
				pts_a = []; vert_a.each{|pt| pts_a << pt.position}
				pts_a << intersect_pt; pts_a.flatten!; pts_a.uniq!
				
				column_face = Sketchup.active_model.entities.add_face(pts_a)
			when 3
				#This code has been written because the array of edges are not regular....They are not sorted sometimes.
				
				#Find the center edge
				center_index = 0 if (column_edge_arr[1].vertices&column_edge_arr[2].vertices).empty?
				center_index = 1 if (column_edge_arr[0].vertices&column_edge_arr[2].vertices).empty?
				center_index = 2 if (column_edge_arr[0].vertices&column_edge_arr[1].vertices).empty?
				arr = [0, 1, 2] - [center_index]
				center_edge = column_edge_arr[center_index]
				
				#Find the common vertex of side edges
				first_common_vertex = column_edge_arr[arr[0]].vertices&center_edge.vertices
				last_common_vertex  = column_edge_arr[arr[1]].vertices&center_edge.vertices
				
				#FInd the face points
				vert1 = column_edge_arr[arr[0]].vertices - [first_common_vertex[0]];vert1 = vert1[0].position
				vert2 = first_common_vertex.first.position
				vert3 = last_common_vertex.first.position
				vert4 = column_edge_arr[arr[1]].vertices - [last_common_vertex[0]];vert4 = vert4[0].position
				
				column_face = Sketchup.active_model.entities.add_face(vert1, vert2, vert3, vert4)
			when 4
				#Other columns
				adjacent_edges = []
				column_edge_arr.each { |column_edge|
					adjacent_edges << find_edges(column_edge, input_face)
				}
				
				if adjacent_edges
					adjacent_edges.flatten!; adjacent_edges.uniq!
					if adjacent_edges.length == 2
						intersect_pt = Geom.intersect_line_line(adjacent_edges[0].line, adjacent_edges[1].line)
						adjacent_edges.each { |adj_edge| 
							common_vertex=nil
							column_edge_arr.each { |col_edge|
								common_vertex = (col_edge.vertices&adj_edge.vertices)[0]
								if common_vertex
									Sketchup.active_model.entities.add_line(intersect_pt, common_vertex.position)
									break
								end
							}
						}
						faces = column_edge_arr[0].faces
						column_edge_arr.each {|column_edge|
							faces = faces&(column_edge.faces-[input_face])						
						}
						column_face = faces[0]
					else
						puts "4 : Something wrong with the adjacent edges"
					end
				end
				
			else
				puts "Column edges more than 4 not supported."
			end

			# face_pts = []
			# column_edge_arr.each_with_index {|col, col_index| 
				# face_pts <<[col.vertices[0], col.vertices[1]] if col_index==0
				# face_pts <<[col.vertices[1], col.vertices[1]] if col_index==1
			# }
			# face_pts << intersect_pt if intersect_pt
			# face_pts.flatten!.uniq!
			
			# puts "face_pts : #{face_pts}"

			# column_face = Sketchup.active_model.entities.add_face(face_pts)
			if column_face
				prev_ents = [];Sketchup.active_model.entities.each{|ent| prev_ents << ent}
				
				# if input_face.normal.z < 0
					# wall_height = -wall_height
				# end
				column_face.reverse! if column_face.normal.z > 0
				column_face.pushpull(wall_height, true)
				curr_ents = [];Sketchup.active_model.entities.each{|ent| curr_ents << ent}
				new_ents = curr_ents - prev_ents
				column_group = Sketchup.active_model.entities.add_group(new_ents)
				column_group.layer = Sketchup.active_model.layers['RIO_Civil_Column']
			end
		}
	end
	
	inner_loop_flag  	= true
	if inner_loop_flag 
		inner_loops 	= input_face.loops - [input_face.outer_loop]
		inner_loops.each {|iloop|
			column_face_flag = true
			loop_faces = []
			iloop.edges.each{|iedge| 
				puts "iedge : #{iedge} : #{iedge.layer.name}"
				column_face_flag = false unless iedge.layer.name.start_with?('RIO_Column')
				loop_faces << iedge.faces
			}
			puts "column_face : #{column_face_flag}"
			if column_face_flag
				#Find the face of the loop.
				loop_faces.flatten!
				loop_faces = loop_faces - [input_face]
				loop_faces.flatten! 
				loop_faces.uniq!
				
				#Do usual pull push upto wall height
				column_face = loop_faces[0]
				prev_ents = [];Sketchup.active_model.entities.each{|ent| prev_ents << ent}
				column_face.reverse! if column_face.normal.z > 0
				column_face.pushpull(wall_height, true)
				curr_ents = [];Sketchup.active_model.entities.each{|ent| curr_ents << ent}
				new_ents = curr_ents - prev_ents
				column_group = Sketchup.active_model.entities.add_group(new_ents)
				column_group.layer = Sketchup.active_model.layers['RIO_Civil_Column']
			end
		}
	end
end

def find_edges sel_edge, sel_face
    edge_arr = []
    sel_edge.vertices.each{|ver|
        #puts ver.edges&sel_face.edges
        common_edges = ver.edges&sel_face.edges
        edge_arr << common_edges
    }
	
    edges = edge_arr.flatten!.uniq! - [sel_edge]
	edges.select!{|ed| ed.layer.name!='RIO_Column'}
	edges
end


def create_beam input_face

	wall_blocks = es.grep(Sketchup::ComponentInstance).select{|inst| inst.definition.name.start_with?('rio_temp_defn')}
	beam_wall_block = nil
	wall_blocks.each{|wblock|
		if wblock.bounds.intersect(input_face.bounds).diagonal > 1.mm
			beam_wall_block = wblock
			break
		end
	}
	unless beam_wall_block
		puts "The wall beams face is not glued to any wall properly"
		return false
	end
	
	block_vector = beam_wall_block.get_attribute :rio_block_atts, 'towards_wall_vector'
	input_face.reverse! if input_face.normal != block_vector 
	
	face_center = input_face.bounds.center
	fnorm 		= input_face.normal
	
	ray_res 		= Sketchup.active_model.raytest(face_center, fnorm)
	reverse_ray_res = Sketchup.active_model.raytest(face_center, fnorm.reverse)
	
	puts "ray_res : #{ray_res}"
	#puts "revsrese ray : #{reverse_ray_res}"
	
	pre_entities = []; post_entities=[];
	Sketchup.active_model.entities.each{|ent| pre_entities << ent}
	if ray_res
		distance = ray_res[0].distance(face_center)
		puts "ray distance : #{distance}"
		if distance > 60.mm
			if ray_res[1][0].get_attribute(:rio_atts,'wall_block')
				puts "ray res : #{ray_res} : #{ray_res[1][0].get_attribute(:rio_atts,'wall_block')}"
				input_face.pushpull(distance, true)
			end
		end
	end
	Sketchup.active_model.entities.each{|ent| post_entities << ent}
	
	new_entities 	= post_entities - pre_entities
	temp_group 		= Sketchup.active_model.entities.add_group(new_entities)
	Sketchup.active_model.layers.add('RIO_CIVIL_Beam') if Sketchup.active_model.layers['RIO_CIVIL_Beam'].nil?
	temp_group.layer = Sketchup.active_model.layers['RIO_CIVIL_Beam']
	return temp_group
	# if reverse_ray_res
		# distance = reverse_ray_res[0].distance(face_center)
		# puts "reverse ray distance : #{distance}"
		# if distance > 60.mm
			# if ray_res[1][0].get_attribute(:rio_atts,'wall_block')
				# puts "Rev ray res : #{ray_res} : #{ray_res[1][0].get_attribute(:rio_atts,'wall_block')}"
				# input_face.pushpull(distance, true)
			# end
		# end
	# end
end


def get_views room_face
	unless room_face.is_a?(Sketchup::Face)
		puts "get_views : Not a Sketchup Face"
		return false
	end

	unknown_edges = []
	room_face.edges.each{ |redge| unknown_edges << redge unless redge.layer.name.start_with?('RIO_')}
	unless unknown_edges.empty?
		seln = Sketchup.active_model.selection; seln.clear; seln.add(unknown_edges)
		puts "The following are unknown edges in the floor."
		return false
	end
	
	# ----------------------------------------------------------------
    # get corner edge
    corner_found = false
	floor_edges_arr = room_face.outer_loop.edges
	floor_edges_arr.length.times do
        f_edge = floor_edges_arr[0]
        puts "f_edge : #{f_edge.layer.name} : #{floor_edges_arr[1].layer.name}"
        #Corner algo 1 : Check for perpendicular walls
        if f_edge.layer.name == 'RIO_Wall'
			next_edge = floor_edges_arr[1]
			if f_edge.get_attribute(:rio_atts, 'door_adjacent') || next_edge.get_attribute(:rio_atts, 'door_adjacent')
				#If the current or next wall is a door adjacent wall.....Skip.....
			else
				if next_edge.layer.name == 'RIO_Wall'
					if f_edge.line[1].perpendicular?(next_edge.line[1]) || f_edge.line[1].perpendicular?(next_edge.line[1].reverse)
						corner_found = true
						#sel.add(f_edge, next_edge)
					end
				end
			end
		end
        puts "corner_found : #{corner_found}"
        floor_edges_arr.rotate!
        break if corner_found
	end
	#floor_edges_arr.rotate!
	
	puts "get_views : #{floor_edges_arr}"
	room_views = []
	#parse each edge
	while_count = 0
	while while_count < 20
		while_count += 1
		view_comps 	= get_wall_view(floor_edges_arr)
		floor_edges_arr = floor_edges_arr - view_comps		
		room_views << view_comps
		floor_edges_arr.flatten!
		break if floor_edges_arr.empty?
	end
	sel.add(floor_edges_arr)
	puts "room : floor_edges_arr : #{floor_edges_arr}"
	room_views
end

def get_wall_view floor_edge_arr
	last_viewed_wall = nil
	view_components = []
	puts "floor_edge_arr : #{floor_edge_arr}"
	floor_edge_arr.each {|floor_edge|
		case floor_edge.layer.name 
		when 'RIO_Wall'
			if last_viewed_wall
				if floor_edge.get_attribute(:rio_atts, 'door_adjacent')
					view_components << floor_edge
				else
					if floor_edge.line[1].perpendicular?(last_viewed_wall.line[1])
						return view_components
					else
						view_components << floor_edge
					end
				end
			else
				last_viewed_wall = floor_edge unless floor_edge.get_attribute(:rio_atts, 'door_adjacent')
				view_components << floor_edge
			end
		when 'RIO_Door', 'RIO_Window'
			if last_viewed_wall && floor_edge.line[1].perpendicular?(last_viewed_wall.line[1])
				return view_components
			else
				view_components << floor_edge
			end
		when 'RIO_Column'
			view_components << floor_edge
		end
	}
	return view_components
end

def check_edge_vector input_edge, input_face
    if !input_edge.is_a?(Sketchup::Edge)
        puts "check_edge_vector : First input should be an Edge : #{input_edge}"
        return false
    end
    if !input_face.is_a?(Sketchup::Face)
        puts "check_edge_vector : Second input should be an Face : #{input_face}"
        return false
    end
    
    edge_vector = input_edge.line[1]
    perpendicular_vector = Geom::Vector3d.new(-edge_vector.y, edge_vector.x, edge_vector.z)
    
    center_pt   = input_edge.bounds.center
    
    offset_pt 	= center_pt.offset(perpendicular_vector, 10.mm)
	res     	= input_face.classify_point(offset_pt)
	if res == Sketchup::Face::PointInside || res == Sketchup::Face::PointOnFace
		return perpendicular_vector
	end
	
	offset_pt 	= center_pt.offset(perpendicular_vector.reverse, 10.mm)
	res     	= input_face.classify_point(offset_pt)
	if res == Sketchup::Face::PointInside || res == Sketchup::Face::PointOnFace
		return perpendicular_vector.reverse
	end
	
	return false
end
