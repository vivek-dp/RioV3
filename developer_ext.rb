#-------------------------------------------------------------------------------------------
#Will contain basic loading stuffs for development
#-------------------------------------------------------------------------------------------

require 'sketchup.rb'
require 'extensions.rb'
require 'time'

# Default code, use or delete...
M = Sketchup.active_model # Open model
E = M.entities # All entities in model
S = M.selection # Current selection

SKETCHUP_CONSOLE.show
chris = Sketchup.active_model.definitions['chris']

chris.instances.each{|c| c.hidden=true} if chris

def mod
	Sketchup.active_model
end

def tt
	return Time.now.utc.iso8601
end

def fsel
	return S[0]
end

def fpid
	return fsel.persistent_id
end

def get_comp_pid id
	Sketchup.active_model.entities.each{|x| return x if x.persistent_id == id};
	return nil;
end

def es
	Sketchup.active_model.entities
end

def stop
  Sketchup.active_model.start_operation 'testing'
end

def abop
  Sketchup.active_model.abort_operation
end

def sel
	Sketchup.active_model.selection
end

def inst_arr
	es.grep(Sketchup::ComponentInstance)
end

def ld
	directory_list = ['controller']
	directory_list.each{|dirname|
		directory = RIO_ROOT_PATH+'/'+dirname
		Dir.entries(directory).each{|file_name| 
			if file_name.end_with?('.rb')
				file_path = File.join(directory, file_name)
				load file_path
			end
		}
	}
end

def cor comp
	corners = []
	(0..7).each{ |i|
		corners << comp.bounds.corner(i)
	}
	corners
end

def double_explode
  Sketchup.active_model.entities.each {|ent| ent.explode if ent.is_a?(Sketchup::ComponentInstance)}
  Sketchup.active_model.entities.each {|ent| ent.explode if ent.is_a?(Sketchup::Group)  }
end

def get_points face
	pts = []
	pts << face.bounds.center
	# pts << face.vertices[0].position
	# pts << face.vertices[1].position
	face.vertices.each {|pt| pts << pt.position}
	#face.edges.each{ |e| pts << e.bounds.center}
	pts.flatten!
	#puts "get_pts : #{pts}"
	return pts
end

def check_ray pt, input_face, hit_face
	flag = false
	#puts "pt : #{pt}"
	ray1 =[pt, Geom::Vector3d.new(input_face.normal.reverse)]
	ray2 =[pt, Geom::Vector3d.new(input_face.normal)]
    item = M.raytest(ray1, false)
	if item && item[1][0] == hit_face
		flag = true 
	end
	item = M.raytest(ray2, false)
	if item && item[1][0] == hit_face
		flag = true 
	end
	return flag
end

def tp
	# Default code, use or delete...
	mod = Sketchup.active_model # Open model
	ent = mod.entities # All entities in model
	sel = mod.selection # Current selection


	op_name = "Ray_test"
	#mod.start_operation(op_name)

	l 	= 	1000
	z	=	500
	pts = [[-l,-l,z], [l,-l,z], [l,l,z], [-l,l,z]]

	hit_face = ent.add_face pts

	double_explode

	face_array = []

	Sketchup.active_model.entities.each{|e|
	  if e.is_a?(Sketchup::Face)
		ray_success = false
		#puts "e : #{e}"
		pts_array = get_points e
		#puts "pts : #{pts_array}"
		pts_array.each {|pt| 
			ray_success = check_ray pt, e, hit_face
			puts "ray status : #{ray_success}"
			next if ray_success
			puts "next"
		}
		face_array << e unless ray_success
=begin		
	    ray1 =[e.bounds.center, Geom::Vector3d.new(e.normal.reverse)]
		ray2 =[e.bounds.center, Geom::Vector3d.new(e.normal)]
	    item = mod.raytest(ray1, false)
		if item && item[1][0] == hit_face
			flag = true 
		end
		item = mod.raytest(ray2, false)
		if item && item[1][0] == hit_face
			flag = true 
		end
		if flag
			puts flag
		else 
			e.erase! if e != hit_face
	    end
=end	   
	  end
	}

	#puts face_array
	puts face_array.length

	vertices=[]

#=begin
	E.each{|e| 
		if e.is_a?(Sketchup::Edge)
			e.erase! if e.faces.empty?
		end
	}
	face_array.each{|f| f.erase! if f != hit_face}
	ent.each{|e| 
		if e.is_a?(Sketchup::Edge)
			e.erase! if e.faces.empty?
		end
	}

	# ent.each{|e| 
	 	#e.erase! if e.is_a?(Sketchup::Face)	
	 #}
#=end
=begin
	face_array.each{|f| f.erase! if f != hit_face}
	ent.each{|e| 
		if e.is_a?(Sketchup::Edge)
			e.erase! if e.faces.empty?
		end
	}

	puts "length"
	puts Sketchup.active_model.entities.length
	counter = 0
	hit_face.erase!
	Sketchup.active_model.entities.each {|e|
		if e.is_a?(Sketchup::Face)	
			counter += 1
			#puts "face : #{e}"
			v = e.vertices
			pts=[];
			v.each{ |ve| posn=ve.position;pt = Geom::Point3d.new(posn.x, posn.y, 0); pts << pt}
			Sketchup.active_model.entities.add_face(pts);
			return if counter == 1000
		end
		
	}
=end
end

def print_all_method_and_values obj
	require 'pp'
	if obj && obj.respond_to?(:methods)
		puts "List of functions and values corresponsing to the #{obj.class} upto 'methods'."
		obj_methods = obj.methods
		obj_hash 	= {}
		obj_methods.each { |method_name|
			break if method_name == :methods
			begin 
				obj_hash[method_name] = obj.send(method_name)
			rescue
				next
			end
		}
		puts obj_hash.pretty_inspect
		puts "-----------------------------------------------------------"
	else
		puts "Not a valid object"
	end
end

def get_attributes component
	if !component.attribute_dictionaries.nil?
		component.attribute_dictionaries.each {|comp_dict|
			puts "----------------------------------------------------"
			puts "\n\n%-30s : %-20s" % ['Dictionary' , comp_dict.name]
			puts "----------------------------------------------------"
			comp_dict.each{ |key, value|
				puts "%-30s : %-20s" % [key, value]
			}
		}
		puts "----------------------------------------------------"
	else
		puts "No dictionary found"
	end
end