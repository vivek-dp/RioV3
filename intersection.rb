def check_intersections
	mod = Sketchup.active_model
	ent = mod.entities
	grp = ent.grep(Sketchup::Group)

	intersections = []
	#
	#gp1= Sketchup.active_model.entities.add_group(sel[0])
	#gp2= Sketchup.active_model.entities.add_group(sel[1])

	if true
		for i in 0...grp.length - 1
		  grp.each{ |g| next if g == grp[i] # skip comparing to self
					   bb = Geom::BoundingBox.new.add(g.bounds.intersect(grp[i].bounds))
					   if bb.valid?
						  puts "#{g.name} and #{grp[i].name} intersect "
						  sz1 = g.entities.grep(Sketchup::Face).length + grp[i].entities.grep(Sketchup::Face).length
						  intersections << [g,grp[i],sz1]
						else
						  puts "#{g.name} and #{grp[i].name} do not intersect"
						end
					  bb.clear
					 }
		end

		intersections.each{|g|
		 if g[0].valid? and  g[1].valid?
		   a = g[0].name.dup
		   b = g[1].name.dup
		   sz1 = g[2]
		   
		   mod.start_operation("test using outer shell")
		   new_grp = g[0].outer_shell(g[1])
			if new_grp
			   sz2 = new_grp.entities.grep(Sketchup::Face).length
			   puts "Geometry Overlaps in #{a} and #{b}" if  sz1!= sz2
			end
		   #mod.abort_operation()
		 end
		}
	end
end

def test_glued_to_api_example
    #assert_nothing_raised do
		point = Geom::Point3d.new 10,20,30
		transform = Geom::Transformation.new point
		model = Sketchup.active_model
		entities = model.active_entities
		path = Sketchup.find_support_file "Bed.skp", "Components/Components Sampler/"
		definitions = model.definitions
		componentdefinition = definitions.load path
		instance = entities.add_instance componentdefinition, transform
		status = instance.glued_to
	#end
end


def explode_to_face entity
	if entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
		exploded_entities 	= entity.explode
		exploded_entities.each{ |exp_ent|
			if exp_ent.is_a?(Sketchup::Face)
				$entity_faces << exp_ent
			else
				explode_to_face exp_ent
			end
		}
	end
end

def check_overlap entity1, entity2
	outer_bounds_intersect_flag = entity1.bounds.intersect(entity2.bounds)
	if outer_bounds_intersect_flag
		puts "Outer bounds intersect : #{entity1} : #{entity2}"
		puts "Checking inner bounds intersection"
		
		$entity_faces 	= []
		entity1_copy 	= entity1.copy
		explode_to_face(entity1_copy)
		group1 			= Sketchup.active_model.entities.add_group($entity_faces)
		total_faces 	= $entity_faces.length
		
		$entity_faces 	= []
		entity2_copy 	= entity2.copy
		explode_to_face(entity2_copy)
		group2 			= Sketchup.active_model.entities.add_group($entity_faces)
		total_faces 	+= $entity_faces.length
		
		new_group		= group1.outer_shell(group2)
		if new_group
			outer_shell_faces = new_group.entities.grep(Sketchup::Face).length
			puts "Geometry Overlaps in #{a} and #{b}" if(total_faces != outer_shell_faces)
		end
		
		#Sketchup.active_model.entities.erase_entities(entity1_copy)
		#Sketchup.active_model.entities.erase_entities(entity2_copy)
		$entity_faces 	= []
	else
		puts "Outer bounds dont intersect"
	end
end 


ents = sel
sel.clear
ents.each{|ed| 
	if ed.is_a?(Sketchup::Edge)
		puts ed.faces.length 
		sel.add(ed) if ed.faces.length != 2
	elsif ed.is_a?(Sketchup::Face)
		edges = ed.faces
		edges.each{ |ent|
			sel.add(ent) if ent.faces.length != 2
		}
	end
}


ents = sel.to_a
sel.clear
ents.each{|ed| 
	if ed.is_a?(Sketchup::Edge)
		puts ed.faces.length, ed
		sel.add(ed) if ed.faces.length != 2
	elsif ed.is_a?(Sketchup::Face)
		edges = ed.faces
		edges.each{ |ent|
			if ent.faces.length == 2
			    puts ent
			    sel.add(ent) 
			end
		}
	end
}

defn_name 	= 't1'
model		= Sketchup.active_model
entities 	= model.entities
defns		= model.definitions
comp_defn	= defns.add defn_name

wall_temp_group 	= comp_defn.entities.add_group
fsel.each { |ent|
	wall_temp_group.entities.add_face(ent)
}


