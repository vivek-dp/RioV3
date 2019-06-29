module RIO
	module DirectionHelper
		def self.get_perpendicular_vector edge
			edge_vector  = edge.line[1]
			perpendicular_vector = Geom::Vector3d.new(-edge_vector.y, edge_vector.x, edge_vector.z)
			perpendicular_vector 
		end
		
		def self.get_pt_face_vector inp_pt, ref_face
			inp_pt.offset()
		end

		#Based on the origin of the entity
		def self.get_entity_vector entity, ref_face
			unless entity
				puts "Entity is Nil."
				return false
			end
			origin = entity.transformation.origin
		end

		def self.rotate_item entity, rotate_axis=Z_AXIS, angle=90
			point = entity.bounds.center
			angle = angle.degrees
			transformation = Geom::Transformation.rotation(point, rotate_axis, angle)
			entity.transform!(transformation)
		end

		def self.get_edge_directional_vector edge, vector
			
		end

		def self.get_sort_params vector
			sort_by_x 		= false
			sort_by_y 		= false
			vector_type 	= false
			corner_index	= false
			start_index		= false

			#For unit vectors
			case vector
			when Y_AXIS.reverse
				sort_by_x 		= 1
				vector_type		= 1
				corner_index	= 0
				start_index		= 2
			when X_AXIS
				sort_by_y 		= 1
				vector_type		= 2
				corner_index 	= 1
				start_index		= 0
			when Y_AXIS
				sort_by_x 		= -1
				vector_type		= 3
				corner_index 	= 3
				start_index		= 1
			when X_AXIS.reverse
				sort_by_y 		= -1
				vector_type		= 4
				corner_index 	= 2
				start_index		= 3
			end		

			unless vector_type
				if vector.x>0&&vector.y<0 #Reverse of Y axis
					sort_by_x 		= -1
					sort_by_y 		= -1
					vector_type		= 5
					corner_index 	= 0
					start_index		= 2
				elsif vector.x>0&&vector.y>0
					sort_by_x 		= 1
					sort_by_y 		= -1
					vector_type		= 6
					corner_index 	= 1
					start_index		= 0
				elsif vector.x<0&&vector.y>0
					sort_by_x 		= 1
					sort_by_y 		= 1
					vector_type		= 7
					corner_index 	= 3
					start_index		= 1
				elsif vector.x<0&&vector.y<0
					sort_by_x 		= -1
					sort_by_y 		= 1
					vector_type		= 8
					corner_index 	= 2
					start_index		= 3
				end
			end

			return sort_by_x , sort_by_y, vector_type, corner_index, start_index
		end

		def self.sort_wall_items entities=[], wall_facing_vector=X_AXIS

			if entities.empty?
				puts "No entities passed to sort."
				return false
			end

			x_sort_flag, y_sort_flag, vector_type, corner_index, start_index = get_sort_params(wall_facing_vector)

			puts "flags : #{x_sort_flag} : #{y_sort_flag} : #{vector_type}"
			sorted_entities = []
			#x_sort_flag = 1
			if x_sort_flag
				puts "X sorting"
				entities = entities.to_a; entities.flatten!
				sorted_entities = entities.sort_by!{|ent| x_sort_flag*ent.bounds.corner(corner_index).x}
			end
			if y_sort_flag
				puts "Y sorting"
				if sorted_entities.empty?
					entities = entities.to_a; entities.flatten!
					sorted_entities = entities.sort_by!{|ent| y_sort_flag*ent.bounds.corner(corner_index).y}
				else
					sorted_entities.sort_by!{|ent| y_sort_flag*ent.bounds.corner(corner_index).y}
				end
			end
			return sorted_entities, start_index
		end


	end 
end