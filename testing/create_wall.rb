
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

wall_faces.each { |wall_face|
	wall_face.outer_loop.edges.each{ |edge|
		verts 	= edge.vertices

		first_vert 		= verts[0]
		second_vert 	= verts[1]

		ray_vector 	= first_vert.position.vector_to second_vert.position

		start_pt	= first_vert.position

		ray = [start_pt, ray_vector.reverse]
		hit_item = Sketchup.active_model.raytest(ray, false)
		#puts "hit_item : #{hit_item}"

		if hit_item && hit_item[1][0].is_a?(Sketchup::Edge)
			if hit_item[1][0].layer.name == 'Wall'
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
			if hit_item[1][0].layer.name == 'Wall'
				distance = second_vert.position.distance hit_item[0]
				#puts distance
				if distance < 250.mm
					wall_line = Sketchup.active_model.entities.add_line second_vert.position, hit_item[0]
					wall_line.layer = wall_layer
				end
			end
		end
	}
}

pts



