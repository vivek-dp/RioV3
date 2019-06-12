require 'pp'

load 'E:\V3\Working\core\SketchupHelper.rb'

def same_vector edge1, edge2
	zero_vector = Geom::Vector3d.new(0,0,0)
	if edge1.line[1] == edge2.line[1]
		return true
	elsif (edge1.line[1]*edge2.line[1])==zero_vector
		return true
	end
	return false
end

remaining_edges = fsel.edges
total_edges = remaining_edges.length

remaining_edges.each{ |curr_edge|
	next_edge = remaining_edges[1]
	remaining_edges.rotate! 
	break if same_vector(curr_edge, next_edge)
}

count = 1; wall = {};
wall_name       = 'wall_%d'%[count]
prev_edge       = remaining_edges[0]
wall[wall_name] = [prev_edge]

remaining_edges[1..total_edges].each { |curr_edge|
	if same_vector(prev_edge, curr_edge)
		wall[wall_name] = [] unless wall[wall_name]
		wall[wall_name] << curr_edge
	else
		count += 1
		wall_name       = 'wall_%d'%[count]
		wall[wall_name] = [curr_edge]
	end
	prev_edge = curr_edge
}

pp wall

wall.each_pair { |key, value|
	sel.add(value)
	sleep(1)
	Sketchup.active_model.active_view.refresh
	sel.clear
}










abort("Message goes here")

#Temp............................................
@native_face = fsel
SketchupHelper = RIO::SketchupHelper

#.................................................

face_normal = @native_face.normal
edges = @native_face.edges
edges << edges[0]

wall_settings = $RIO_SET[:ANALYSIS]['civil_settings']['Wall']
wall_min_length = wall_settings['Length_minimum'] #Better change at the settings level
wall_max_length = wall_settings['Length_maximum']+1


edges.each { | face_edge |
	if face_edge.layer.name == 'RIO_Door'
		door_adj_edges = SketchupHelper::get_adjacent_edges face_edge, @native_face
		door_adj_edges.each { |adj_edge|
			adj_length = adj_edge.length
			angle = SketchupHelper::angle_between_face_edges face_edge, adj_edge, @native_face.normal
			puts "Details : #{angle.radians.round}, #{adj_length}, #{wall_min_length}, #{wall_max_length}"

			if angle.radians.round == 90 && adj_length < wall_max_length
				puts "Angle is 90 and length less"
				adj_edge.set_attribute(:rio_atts, 'wall_adjacent_edge', 'true')
			end
		}
	end
}