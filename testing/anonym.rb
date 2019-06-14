def get_comp_pid id
	Sketchup.active_model.entities.each{|x| return x if x.persistent_id == id};
	return nil;
end

id 			= 11771
new_line 	= get_comp_pid id
inst 		= fsel

offset_vector = inst.bounds.center.vector_to new_line.bounds.center



