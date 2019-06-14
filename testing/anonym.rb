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

	
def t2
	load 'E:\V3\Working\testing\anonym.rb'
	get_wall_points
end

def get_outer_walls
	wall_edges 	= Sketchup.active_model.entities.grep(Sketchup::Edge).select{|edge| edge.layer.name == 'RIO_Wall'} 
	walls 		= wall_edges.select{|x| x.faces.length == 1}
	walls
end

get_wall_points
outer_walls

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
	outer_walls.each { |wall|
		verts = wall.vertices
		create_wall_instance(verts[0].position, verts[1].position, wall_width)
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

def room_walls room_face
	return "No value sent" unless room_face
	return "Please select a face" unless room_face.is_a?(Sketchup::Face) 
	
	wall_width 	= 50.mm
	
	room_wall_edges = room_face.edges.select{|edge| edge.layer.name == 'RIO_Wall'} 
	room_wall_edges.each{ |edge|
		verts = edge.vertices
		
		pt1, pt2 = verts[0].position, verts[1].position
		
		clockwise = check_clockwise_edge edge, room_face
		if clockwise
			pt1, pt2 = verts[0].position, verts[1].position
		else
			pt1, pt2 = verts[1].position, verts[0].position
		end
		
		create_wall_instance(pt1, pt2, wall_width)
	}
end

def create_wall_instance pt1, pt2, wall_width=50.mm
	
	pt1 = pt1.position if pt1.is_a?(Sketchup::Vertex)
	pt2 = pt2.position if pt2.is_a?(Sketchup::Vertex)
	
	puts "add_wall : #{pt1} : #{pt2}"

	length 			= pt1.distance(pt2).mm
	
	wall_defn 		= WallDraw.new.create_entity length, wall_width, WALL_HEIGHT
	
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
	
	#For developments
	color = Sketchup::Color.names[rand(140)]
	inst.material = color
	
	inst
end



