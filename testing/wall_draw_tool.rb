
class WallDraw
	def activate
		puts 'Your tool has been activated.'
		@wall_points_a = []
		@ip1 = nil
		@color_array 		= Sketchup::Color.names
	end

	def deactivate(view)
		puts "Your tool has been deactivated in view: #{view}"
		@wall_points_a = nil
		@ip1 = nil
		@color_array = nil
	end
	
	def draw(view)
		puts "draw called : #{view}"
		view.drawing_color= Sketchup::Color.new("Orange")
		arr = [ Geom::Point3d.new(0,0,0), Geom::Point3d.new(1000,1000,1000)]
		view.draw(GL_LINES, arr)
	end
	
	def onLButtonUp(flags, x, y, view)
		if @wall_points_a.size > 1
			puts @wall_points_a
			pt1 = @wall_points_a[0][:point]
			pt2 = @wall_points_a[1][:point]
			#line = Sketchup.active_model.entities.add_line(pt1, pt2)
			wall_face =	draw_face(pt1, pt2)
			
			wall_height = 1000.mm
			color = @color_array[rand(140)]
			wall_face.material = color
			wall_face.back_material = color
			wall_face.pushpull -wall_height
			
			#line.find_faces
		end
		puts "onLButtonUp"
		view.refresh # calls getExtents() then draw() method
	end

	def onLButtonDown(flags,x,y,view)
		puts "onLButtonDown : #{flags} : #{x} : #{y} : #{view}"
		ph = view.pick_helper
		ph.do_pick x, y
		entity = ph.best_picked
		
		
		@ip1 = Sketchup::InputPoint.new unless @ip1
		@ip1.pick view, x, y
		puts "Point clicked : #{@ip1.position}"
		
		#point = p
		pick_h = {
			:flags 	=> flags,
			:x 		=> x,
			:y 		=> y,
			:view 	=> view,
			:point	=> @ip1.position,
		}
		
		@wall_points_a.shift if @wall_points_a.size > 1
		@wall_points_a << pick_h
		puts "Entity picked : #{entity}"
	end
	
	def draw_face pt1, pt2, wall_offset=100.mm
		lv	=	pt1.vector_to(pt2) #Line vector
		perp_vector 	= Geom::Vector3d.new(lv.y, -lv.x, lv.z)
		perp_2d_vector_a	= [perp_vector, perp_vector.reverse] #Perpendicular 2d vectors
		
		face_points = []
		perp_2d_vector_a.each_with_index { |perp_vector, index|
			temp1 	= pt1.offset(perp_vector, wall_offset)
			temp2	= pt2.offset(perp_vector, wall_offset)
			if index == 1
				face_points << [temp1, temp2]
			else
				face_points << [temp2, temp1]
			end
			puts "perp : #{perp_vector}"
		}
		face_points.flatten!
		puts "face_points : #{face_points}"
		wall_face = Sketchup.active_model.entities.add_face(face_points)
		wall_face
	end
	
	# def onMouseMove(flags, x, y, view)
		# @mm.pick view, x, y
		# puts "onMouseMove : #{@mm.position}"
	# end
end

# load 'E:\V3\Working\testing\wall_draw_tool.rb';wd=WallDraw.new;Sketchup.active_model.select_tool(wd)