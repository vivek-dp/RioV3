require_relative '../core/CivilHelper.rb'

def door_face_identification input_face
	model 	= Sketchup.active_model
	ents	= model.entities
	input_face_edges = input_face.outer_loop.edges
	pts = []
	door_edges = input_face_edges.select{|ent| ent.layer.name == 'RIO_Door'}
	
	puts "door_edges : #{door_edges}"
	door_edges.each { |door_edge|
		puts "door_edge : #{door_edge}"
		faces = door_edge.faces
		door_vertices = door_edge.vertices
		
		common_edges = []
		perpendicular_edges = []
		input_face_edges.each{ |face_edge|
			common_edges << face_edge unless (face_edge.vertices&door_vertices).empty?
		}
		puts "coomon_edge : #{common_edges}"
		common_edges.each { |common_edge|
			perpendicular_edges << common_edge if door_edge.line[1].perpendicular?(common_edge.line[1])
		}
		if perpendicular_edges.empty?
			puts "Something peculiar about this door #{door_edge.persistent_id}"
			next
		end
		perpendicular_edges.sort_by!{|pedge| pedge.length}
		puts "perpendicular_edges : #{perpendicular_edges}"
		if perpendicular_edges.length == 2
			wall_edge = perpendicular_edges[0]
			if wall_edge.length < 251.mm
				offset_len 	= wall_edge.length
			else
				offset_len = 250.mm
			end
			tw_vector 	= RIO::CivilHelper::check_edge_vector door_edge, input_face
			puts "tw_vector : #{tw_vector}"
			#face_pts 	= [door_vertices[0].position]
			#face_pts 	<< door_vertices[0].position.offset(tw_vector, offset_len)
			#face_pts 	<< door_vertices[1].position.offset(tw_vector, offset_len)
			#face_pts	<< door_vertices[1].position
			if tw_vector
				pt1 = door_vertices[0].position.offset(tw_vector, offset_len)
				pt2 = door_vertices[1].position.offset(tw_vector, offset_len)
				pts << [pt1, pt2]
				
			end
			
			#new_face 	= ents.add_face(face_pts)
			#new_face.set_attribute(:rio_atts, 'wall_face', 'true')
		end
	}
	unless pts.empty?
		pts.each{|arr|
			new_line = ents.add_line(arr[0], arr[1])
			new_line.layer = Sketchup.active_model.layers['RIO_Door']
		}
	end
	# door_edges.each{ |door_edge|
		# sel.add(door_edge)
		# faces = door_edge.faces
		# door_vertices = door_edge.vertices
		# if faces.length == 1 #External door
			# common_edges = []
			# perpendicular_edges = []
			# faces[0].edges.each{ |face_edge|
				# common_edges << face_edge if face_edge.vertices&door_vertices
			# }
			# common_edges.each { |common_edge|
				# perpendicular_edges << common_edge if door_edge.line[1].perpendicular?(common_edge.line[1])
			# }
			# if perpendicular_edges.empty?
				# puts "Something peculiar about this door #{door_edge.persistent_id}"
				# next
			# end
			# perpendicular_edges.sort_by!{|pedge| pedge.length}
			# wall_edge = perpendicular_edges[0]
			# if wall_edge.length < 251.mm
				# offset_len 	= wall_edge.length
			# else
				# offset_len = 250.mm
			# end
			# tw_vector 	= RIO::CivilHelper::check_edge_vector door_edge, input_face
			# puts "tw_vector : #{tw_vector}"
			# face_pts 	= [door_vertices[0].position]
			# face_pts 	<< door_vertices[0].position.offset(tw_vector, offset_len)
			# face_pts 	<< door_vertices[1].position.offset(tw_vector, offset_len)
			# face_pts	<< door_vertices[1].position
			# new_face 	= ents.add_face(face_pts)
			# new_face.set_attribute(:rio_atts, 'wall_face', 'true')
		# elsif faces.length == 2
			# common_edges = []
			# perpendicular_edges = []
			# faces.each { |door_face|
				# door_face.edges.each{ |face_edge|
					# common_edges << face_edge if face_edge.vertices&door_vertices
				# }
			# }
			# common_edges.each { |common_edge|
				# perpendicular_edges << common_edge if door_edge.line[1].perpendicular?(common_edge.line[1])
			# }
			# if perpendicular_edges.empty?
				# puts "Something peculiar about this door #{door_edge.persistent_id}"
				# next
			# end
			# perpendicular_edges.sort_by!{|pedge| pedge.length}
			# wall_edge = perpendicular_edges[0]
			# if wall_edge.length < 251.mm
				# offset_len 	= wall_edge.length
			# else
				# offset_len = 250.mm
			# end
			
		# end
	# }
end