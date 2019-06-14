class WallDraw
	WALL_WIDTH = 200.mm
	WALL_HEIGHT = 2000.mm
	
	attr_accessor :wall_width
	
	def initialize(width=200.mm)
		@wall_width = width
		@user_text_entered = false
	end
	
	def activate
		puts 'WallDraw : activated.'
		
		@mouse_ip 			= Sketchup::InputPoint.new
		@first_picked_point = Sketchup::InputPoint.new
		
		@wall_points_a 		= []
		@color_array 		= Sketchup::Color.names
		
		@width 
	end

	def deactivate(view)
		puts "WallDraw : deactivated view: #{view}"
		@wall_points_a = nil
		@first_picked_point = nil
		@color_array = nil
		view.invalidate
	end
	
	#-----------	Tool Events start 	-------------------------------------------------------
	def picked_points
        points = []
        points << @first_picked_point.position if @first_picked_point.valid?
        points << @mouse_ip.position if @mouse_ip.valid?
        points
	end
	
	def draw_preview(view)
		points = picked_points
        return unless points.size == 2
		#puts "draw preview.... #{points}"
        view.set_color_from_line(*points)
        view.line_width = 10
        view.line_stipple = "-.-"
        view.draw(GL_LINES, points)
	end
	
	def draw(view)
		draw_preview(view)
		@mouse_ip.draw(view) if @mouse_ip.display?
	end
	
	def enableVCB?
		return true
	end
	
	def onUserText(text, view)
		puts "User text : #{text} : #{view}"
		length = text.to_l
		if @first_picked_point.valid?
			# @mouse_ip.pick(view, x, y, @first_picked_point)
			# puts "Posn : #{@mouse_ip.position} : #{@first_picked_point.position}"
			# distance = @mouse_ip.position.distance @first_picked_point.position
			# if distance > 10.mm
				
			# end
			@wall_width = length
		end
		@user_text_entered = true
	rescue ArgumentError
		view.tooltop = 'Invalid length'
	end
	
	
	
	
	def get_current_entities
		ent_a = []
		Sketchup.active_model.entities.each{|ent| ent_a << ent}
		ent_a
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
	
	def add_wall pt1, pt2
		#line = Sketchup.active_model.entities.add_line(pt1, pt2)
		wall_face =	draw_face(pt1, pt2, @wall_width)
		
		color = @color_array[rand(140)]
		
		prev_entities = []; Sketchup.active_model.entities.each { |ent| prev_entities << ent }
		wall_face.material = color
		wall_face.back_material = color
		wall_face.pushpull -WALL_HEIGHT
		curr_entities = []; Sketchup.active_model.entities.each { |ent| curr_entities << ent }
		
		new_entities = curr_entities - prev_entities
		
		puts "new entities : #{new_entities}"
		@wall_group = Sketchup.active_model.entities.add_group(new_entities)
		@wall_group
	end
	
	#Use reverse for flipping the component
	def add_wall_entity pt1, pt2, type='normal'
		new_line = Sketchup.active_model.entities.add_line(pt1, pt2)
		
		length 			= pt1.distance(pt2).mm
		
		wall_defn 		= create_entity length, @wall_width, WALL_HEIGHT
		trans_vector 	= pt1.vector_to pt2
		orig_trans 		= Geom::Transformation.new(trans_vector)
		
		#Reversing to make sure all the vector point towards the origin....
		extra = 0
		if type == 'reverse'
			extra 	=  Math::PI
			if trans_vector.y < 0
				trans_vector.reverse! 
				placement_point = pt1
			else
				placement_point = pt2
			end
			#trans_vector = pt2.vector_to pt1
		else
			if trans_vector.y < 0
				trans_vector.reverse! 
				placement_point = pt2
			else
				placement_point = pt1
			end
		end
		
		angle 	= extra + X_AXIS.angle_between(trans_vector)
		puts "add_wall_entity : angle is  : #{angle.radians} : #{placement_point} : #{trans_vector}"
		
		#Add instance
		inst = Sketchup.active_model.entities.add_instance wall_defn, placement_point
		
		#Rotate instance
		inst.transform!(Geom::Transformation.rotation(placement_point, Z_AXIS, angle))
		
		#For center
		if type == 'center'
			offset_vector 	= inst.bounds.center.vector_to new_line.bounds.center
			trans 			= Geom::Transformation.new(Geom::Point3d.new(offset_vector.x, offset_vector.y, 0))
			inst.transform!(trans)
		end

		
		#For development
		color = Sketchup::Color.names[rand(140)]
		inst.material = color
		
		
		inst
	end
	#------------- 	Tool Events end		---------------------------------------------------------
	
	#------------- Mouse Events Start ----------------------------------------------------------------
	def onLButtonUp(flags, x, y, view)
		if @wall_points_a.size > 1
			puts @wall_points_a
			pt1 = @wall_points_a[0][:point]
			pt2 = @wall_points_a[1][:point]
			#new_wall = add_wall pt1, pt2
			new_wall = add_wall_entity pt1, pt2
			@user_text_entered = false
		end
		puts "onLButtonUp"
		view.refresh # calls getExtents() then draw() method
	end

	def onLButtonDown(flags,x,y,view)
		puts "onLButtonDown : #{flags} : #{x} : #{y} : #{view}"
		ph = view.pick_helper
		ph.do_pick x, y
		entity = ph.best_picked
		
		
		@first_picked_point = Sketchup::InputPoint.new unless @first_picked_point
		@first_picked_point.pick view, x, y
		puts "Point clicked : #{@first_picked_point.position}"
		
		#point = p
		pick_h = {
			:flags 	=> flags,
			:x 		=> x,
			:y 		=> y,
			:view 	=> view,
			:point	=> @first_picked_point.position,
		}
		
		@wall_points_a.shift if @wall_points_a.size > 1
		@wall_points_a << pick_h
		puts "Entity picked : #{entity}"
	end
	
	def onMouseMove(flags, x, y, view)
		if @first_picked_point.valid?
			@mouse_ip.pick(view, x, y, @first_picked_point)
			distance = @mouse_ip.position.distance @first_picked_point.position
			Sketchup.vcb_value = distance
			#puts "distance : #{distance}"
		else
			@mouse_ip.pick(view, x, y)
		end
		if @mouse_ip.valid?
			#puts "Tool tip : #{@mouse_ip.tooltip}"
			view.tooltip = @mouse_ip.tooltip 			
		end
		view.invalidate
	end
	
	# def onMouseMove(flags, x, y, view)
		# @mm.pick view, x, y
		# puts "onMouseMove : #{@mm.position}"
	# end
	#------------- Mouse Events End ----------------------------------------------------------------
	
	#------------- Other functions -----------------------------------------------------------------
	def draw_face pt1, pt2, wall_offset=200.mm
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
	
	def update_status
		if @first_picked_point.valid?
			Sketchup.status_text = "Select Wall End."
		else
			Sketchup.status_text = "Select Wall Start."
		end
	end
end

# load 'E:\V3\Working\testing\wall_draw_tool.rb';wd=WallDraw.new;Sketchup.active_model.select_tool(wd)