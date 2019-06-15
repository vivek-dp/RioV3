# All the Helper functions for the wall building block should be written here.
#

WALL_HEIGHT = 3000.mm

def t2
	load 'E:\V3\Working\testing\wall_helper.rb'
	#get_wall_points
end

def get_comp_pid id
	Sketchup.active_model.entities.each{|x| return x if x.persistent_id == id};
	return nil;
end

def get_wall_points
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
	
	puts "wall_faces : #{wall_faces}"
	if false
		wall_faces.each {|face|
			face.edges.each{ |edge|
				verts =  edge.vertices
				verts.each{ |vert|
					other_vert = verts - [vert]
					other_vert = other_vert[0]
					puts "vert : #{vert} : #{other_vert} : #{verts}"
					
					vector 	= vert.position.vector_to(other_vert).reverse
					pt 		= vert.position.offset vector, 10.mm
					res 	= face.classify_point(pt)
					puts "res : #{res} : #{edge} "
					if res == Sketchup::Face::PointInside || res == Sketchup::Face::PointOnFace
						ray = [vert.position, vector]
						hit_item 	= model.raytest(ray, false)
						puts hit_item, hit_item[1][0].layer
						if hit_item[1][0].layer.name == 'RIO_Wall'
							puts "Wall..."
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
						if distance < 250.mm
							wall_line = Sketchup.active_model.entities.add_line first_vert.position, hit_item[0]
							wall_line.layer = wall_layer
						end
					end
				end


				start_pt	= second_vert.position

				ray = [start_pt, ray_vector]
				hit_item = Sketchup.active_model.raytest(ray, false)
				#puts "hit_item : #{hit_item}"

				if hit_item && hit_item[1][0].is_a?(Sketchup::Edge)
					if hit_item[1][0].layer.name == 'RIO_Wall'
						distance = second_vert.position.distance hit_item[0]
						#puts distance
						if distance < 250.mm
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

#get_wall_points
#outer_walls

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

def check_edge_direction edge, face
	
end

def check_clockwise_edge edge, face
	#Temp code
	edge, face = face, edge if edge.is_a?(Sketchup::Face)
	
	conn_vector = find_edge_face_vector(edge, face)
	dot_vector	= conn_vector * edge.line[1]
	
	clockwise = dot_vector.z > 0
	if clockwise
		puts "Clockwise"
	else
		puts "Anti clockwise"
	end
	return clockwise
end

def create_room room_face
	return "No value sent" unless room_face
	return "Please select a face" unless room_face.is_a?(Sketchup::Face) 
	
	wall_width 		= 50.mm
	window_height 	= 700.mm
	window_offset	= 1000.mm
	wall_height 	= WALL_HEIGHT 
	door_height		= 2000.mm
	
	room_wall_edges = room_face.edges.select{|edge| edge.layer.name == 'RIO_Wall'} 
	room_wall_edges.select{|e| e.layer.name == 'RIO_Wall'}.each{ |edge|
		verts = edge.vertices
		
		clockwise = check_clockwise_edge edge, room_face
		if clockwise
			pt1, pt2 = verts[0].position, verts[1].position
		else
			pt1, pt2 = verts[1].position, verts[0].position
		end
		
		wall_inst = create_wall_instance(pt1, pt2, wall_height: wall_height)
	}
	puts "Room Walls created..."
	
	room_face.edges.select{|e| e.layer.name == 'RIO_Door'}.each{ |door_edge|
		puts "Door : #{door_edge}"
		create_door door_edge, room_face, door_height, wall_height
	}
	puts "Room Doors created"
	
	room_face.edges.select{|e| e.layer.name == 'RIO_Window'}.each{ |window_edge|
		puts "Window : #{window_edge}"
		create_window window_edge, room_face, window_height, window_offset, wall_height
	}
	puts "Room Windows created"
end


def create_wall_instance( pt1, pt2, 
						wall_width: 50.mm, 
						wall_height: 2000.mm, 
						at_height: 0.mm)
	
	pt1 = pt1.position if pt1.is_a?(Sketchup::Vertex)
	pt2 = pt2.position if pt2.is_a?(Sketchup::Vertex)
	
	puts "create_wall_instance params : #{method(__method__).parameters}"

	length 			= pt1.distance(pt2).mm
	
	#create 
	wall_defn 		= create_entity length, wall_width, wall_height
	
	#Add instance
	inst = Sketchup.active_model.entities.add_instance wall_defn, pt1
	
	extra = 0
	#Rotate instance
	trans_vector = pt1.vector_to(pt2)
	if trans_vector.y < 0
		trans_vector.reverse! 
		extra = Math::PI
	end
	angle 	= extra + X_AXIS.angle_between(trans_vector)
	inst.transform!(Geom::Transformation.rotation(pt1, Z_AXIS, angle))
	
	if at_height > 0.mm
		inst.transform!(Geom::Transformation.new([0,0,at_height]))
	end
	
	#For developments
	color = Sketchup::Color.names[rand(140)]
	inst.material = color
	
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
		puts "redge : #{redge}"
		unless (redge.vertices&door_edge.vertices).empty?
			angle = door_edge.line[1].angle_between redge.line[1]
			puts "angle : #{angle}"
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
	
	#Check if the window is an external window
	create_external_window = true
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

def create_column 

end