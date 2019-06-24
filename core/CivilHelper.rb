rioload_ruby '/core/SketchupHelper'
module RIO
    module CivilHelper
        def self.add_wall_corner_lines
            model 	    = Sketchup.active_model
            wall_layer  = model.layers['RIO_Wall']
            pts = []; wall_faces = []
            all_faces = Sketchup.active_model.entities.grep(Sketchup::Face)

            #Get faces with all wall sides
            all_faces.each{|sk_face|
                wall_face_flag = true
                sk_face.edges.each{|edge|
                    wall_face_flag = false if edge.layer.name != 'RIO_Wall'
                }
                wall_faces << sk_face if wall_face_flag
            }

            if true #Core algo for finding the corner lines
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
                                if distance < 251.mm
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
                                if distance < 251.mm
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

        def self.check_clockwise_edge edge, face
            edge, face = face, edge if edge.is_a?(Sketchup::Face)
            conn_vector = find_edge_face_vector(edge, face)
            dot_vector	= conn_vector * edge.line[1]
            clockwise = dot_vector.z > 0
            return clockwise
        end

        def self.check_edge_vector input_edge, input_face
            if !input_edge.is_a?(Sketchup::Edge)
                puts "check_edge_vector : First input should be an Edge : #{input_edge}"
                return false
            end
            if !input_face.is_a?(Sketchup::Face)
                puts "check_edge_vector : Second input should be an Face : #{input_face}"
                return false
            end

            edge_vector = input_edge.line[1]
            perpendicular_vector = Geom::Vector3d.new(-edge_vector.y, edge_vector.x, edge_vector.z)

            center_pt   = input_edge.bounds.center

            offset_pt 	= center_pt.offset(perpendicular_vector, 10.mm)
            res     	= input_face.classify_point(offset_pt)
            if res == Sketchup::Face::PointInside || res == Sketchup::Face::PointOnFace
                return perpendicular_vector
            end

            offset_pt 	= center_pt.offset(perpendicular_vector.reverse, 10.mm)
            res     	= input_face.classify_point(offset_pt)
            if res == Sketchup::Face::PointInside || res == Sketchup::Face::PointOnFace
                return perpendicular_vector.reverse
            end

            return false
        end

        def self.create_cuboidal_entity length, width, height
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

            ent_list1 	= SketchupHelper::get_current_entities
            wall_temp_face.pushpull -height
            ent_list2 	= SketchupHelper::get_current_entities

            new_entities 	= ent_list2 - ent_list1

            new_entities.grep(Sketchup::Face).each { |tface|
                wall_temp_group.entities.add_face tface
            }
            comp_defn
        end

        #-------------------------------------------------------------------------------------
        # The function will be used to create a cuboid component and placed on the edge
        # start point will be the origin for the cuboid component
        # End point will be used to calculate the distance and vector
        # comp height will refer to depth of the component
        # at_offset will refer to the height at which the component has to be placed with reference to the start_point
        #--------------------------------------------------------------------------------------
        def self.place_cuboidal_component( start_point, end_point,
                        comp_width: 50.mm,
                        comp_height: 2000.mm,
                        at_offset: 0.mm)

            start_point = start_point.position if start_point.is_a?(Sketchup::Vertex)
            end_point   = end_point.position if end_point.is_a?(Sketchup::Vertex)
            length 		= start_point.distance(end_point).mm

            #create
            comp_defn 	= create_cuboidal_entity length, comp_width, comp_height

            #Add instance
            comp_inst        = Sketchup.active_model.entities.add_instance comp_defn, start_point

            extra = 0
            #Rotate instance
            trans_vector = start_point.vector_to(end_point)
            if trans_vector.y < 0
                trans_vector.reverse!
                extra = Math::PI
            end
            angle 	= extra + X_AXIS.angle_between(trans_vector)
            comp_inst.transform!(Geom::Transformation.rotation(start_point, Z_AXIS, angle))

            if at_offset > 0.mm
                comp_inst.transform!(Geom::Transformation.new([0,0,at_offset]))
            end

            comp_inst.set_attribute :rio_atts, 'wall_block', 'true'
            comp_inst
        end

        def self.find_adj_window_face arr=[]
            face = arr.last
            face.edges.each{|edge|
                edge.faces.each{|face|
                    window_edges = face.edges.select{|face_edge| face_edge.layer.name=='RIO_Window'}
                    # puts window_edges.count
                    if window_edges.count > 1 && !arr.include?(face)
                        if face.edges.count == 4
                            arr.push(face)
                            find_adj_window_face arr
                        end
                    end
                }
            }
            return arr
        end

        def self.find_edge_face_vector edge, face
            return false if edge.nil? || face.nil?
            edge_vector = edge.line[1]
            perp_vector = Geom::Vector3d.new(edge_vector.y, -edge_vector.x, edge_vector.z)
            offset_pt 	= edge.bounds.center.offset(perp_vector, 2.mm)
            res = face.classify_point(offset_pt)
            return perp_vector if (res == Sketchup::Face::PointInside||res == Sketchup::Face::PointOnFace)
            return perp_vector.reverse
        end

        def self.find_edges sel_edge, sel_face
            edge_arr = []
            sel_edge.vertices.each{|ver|
                #puts ver.edges&sel_face.edges
                common_edges = ver.edges&sel_face.edges
                edge_arr << common_edges
            }

            edges = edge_arr.flatten!.uniq! - [sel_edge]
            edges.select!{|ed| ed.layer.name!='RIO_Column'}
            edges
        end

        def self.get_wall_views room_face
            unless room_face.is_a?(Sketchup::Face)
                puts "get_views : Not a Sketchup Face"
                return false
            end

            unknown_edges = []
            room_face.edges.each{ |redge| unknown_edges << redge unless redge.layer.name.start_with?('RIO_')}
            unless unknown_edges.empty?
                seln = Sketchup.active_model.selection; seln.clear; seln.add(unknown_edges)
                puts "The following are unknown edges in the floor."
                return false
            end

            # ----------------------------------------------------------------
            # get corner edge
            corner_found = false
            floor_edges_arr = room_face.outer_loop.edges
            floor_edges_arr.length.times do
                f_edge = floor_edges_arr[0]
                puts "f_edge : #{f_edge.layer.name} : #{floor_edges_arr[1].layer.name}"
                #Corner algo 1 : Check for perpendicular walls
                if f_edge.layer.name == 'RIO_Wall'
                    next_edge = floor_edges_arr[1]
                    if f_edge.get_attribute(:rio_atts, 'door_adjacent') || next_edge.get_attribute(:rio_atts, 'door_adjacent')
                        #If the current or next wall is a door adjacent wall.....Skip.....
                    else
                        if next_edge.layer.name == 'RIO_Wall'
                            if f_edge.line[1].perpendicular?(next_edge.line[1]) || f_edge.line[1].perpendicular?(next_edge.line[1].reverse)
                                corner_found = true
                                #sel.add(f_edge, next_edge)
                            end
                        end
                    end
                end
                puts "corner_found : #{corner_found}"
                floor_edges_arr.rotate!
                break if corner_found
            end
            #floor_edges_arr.rotate!

            puts "get_views : #{floor_edges_arr}"
            room_views = []
            #parse each edge
            while_count = 0
            while while_count < 20
                while_count += 1
                view_comps 	= get_wall_view(floor_edges_arr)
                floor_edges_arr = floor_edges_arr - view_comps
                room_views << view_comps
                floor_edges_arr.flatten!
                break if floor_edges_arr.empty?
            end
            sel.add(floor_edges_arr)
            puts "room : floor_edges_arr : #{floor_edges_arr}"
            room_views
        end #get_views

        def self.get_wall_view floor_edge_arr
            last_viewed_wall = nil
            view_components = []
            puts "floor_edge_arr : #{floor_edge_arr}"
            floor_edge_arr.each {|floor_edge|
                case floor_edge.layer.name
                when 'RIO_Wall'
                    if last_viewed_wall
                        if floor_edge.get_attribute(:rio_atts, 'door_adjacent')
                            view_components << floor_edge
                        else
                            if floor_edge.line[1].perpendicular?(last_viewed_wall.line[1])
                                return view_components
                            else
                                view_components << floor_edge
                            end
                        end
                    else
                        last_viewed_wall = floor_edge unless floor_edge.get_attribute(:rio_atts, 'door_adjacent')
                        view_components << floor_edge
                    end
                when 'RIO_Door', 'RIO_Window'
                    if last_viewed_wall && floor_edge.line[1].perpendicular?(last_viewed_wall.line[1])
                        return view_components
                    else
                        view_components << floor_edge
                    end
                when 'RIO_Column'
                    view_components << floor_edge
                end
            }
            return view_components
        end

        def self.create_beam input_face

            wall_blocks = es.grep(Sketchup::ComponentInstance).select{|inst| inst.definition.name.start_with?('rio_temp_defn')}
            beam_wall_block = nil
            wall_blocks.each{|wblock|
                if wblock.bounds.intersect(input_face.bounds).diagonal > 1.mm
                    beam_wall_block = wblock
                    break
                end
            }
            unless beam_wall_block
                face_cent_pt = input_face.bounds.center
                test1_pt, test1_item = Sketchup.active_model.raytest(face_cent_pt, input_face.normal)
                if test1_pt
                    distance1 = test1_pt.distance(face_cent_pt)       
                end
                test2_pt, test2_item = Sketchup.active_model.raytest(face_cent_pt, input_face.normal.reverse)
                if test2_pt
                    distance2 = test2_pt.distance(face_cent_pt)       
                end
                if distance1.nil?&distance2.nil?
                    puts "The wall beams face is not glued to any wall properly"
                    return false
                end

                if distance1.nil?
                    beam_wall_block = hit_item[1][0]
                elsif distance2.nil?
                    beam_wall_block = hit_item[1][0]
                else
                    beam_wall_block = distance1<distance2 ? test1_item[0] : test2_item[0]  
                end
            end
            
            block_vector = beam_wall_block.get_attribute :rio_block_atts, 'towards_wall_vector'
            input_face.reverse! if input_face.normal != block_vector #Instead reversing the normal
            
            face_center = input_face.bounds.center
            fnorm 		= input_face.normal
            #fnorm.reverse! if input_face.normal != block_vector

            beam_hit_found = false
            distance = 0.mm

            start_pts = [face_center]
            start_pts << input_face.vertices
            start_pts.flatten!
            start_pts.uniq! #Not needed

            beam_components = Sketchup.active_model.entities.select{|ent| ent.layer.name=='RIO_Civil_Beam'}
            beam_components.each{|ent| ent.hidden=true}
            puts "beam_components : #{beam_components}"
            #First finish checking all opposite walls
            start_pts.each { |start_pt|
                start_pt = start_pt.position if start_pt.is_a?(Sketchup::Vertex)
                hit_point, hit_item     = Sketchup.active_model.raytest(face_center, fnorm)
                if hit_point[0] && hit_item[0].is_a?(Sketchup::ComponentInstance)
                    if hit_item[0].get_attribute(:rio_atts, 'wall_block')
                        beam_hit_found = hit_item[0]
                        distance = start_pt.distance(hit_point)
                    end
                end
            }

            beam_components.each{|ent| ent.hidden=false}

            if beam_hit_found
                pre_entities = Sketchup.active_model.entities.to_a
                input_face.pushpull(distance, true)
                post_entities = Sketchup.active_model.entities.to_a
                new_entities 	= post_entities - pre_entities
                temp_group 		= Sketchup.active_model.entities.add_group(new_entities)
                Sketchup.active_model.layers.add('RIO_Civil_Beam') if Sketchup.active_model.layers['RIO_Civil_Beam'].nil?
                temp_group.layer = Sketchup.active_model.layers['RIO_Civil_Beam']
                return temp_group
            else
                puts "No opposite Wall found.Cannot draw wall"
                return false
            end

            if false
                ray_res 		= Sketchup.active_model.raytest(face_center, fnorm)
                reverse_ray_res = Sketchup.active_model.raytest(face_center, fnorm.reverse)
                
                puts "ray_res : #{ray_res}"
                #puts "reverse ray : #{reverse_ray_res}"
                
                pre_entities = []; post_entities=[];
                Sketchup.active_model.entities.each{|ent| pre_entities << ent}
                if ray_res
                    distance = ray_res[0].distance(face_center)
                    puts "ray distance : #{distance}"
                    if distance > 60.mm
                        if ray_res[1][0].get_attribute(:rio_atts,'wall_block')
                            puts "ray res : #{ray_res} : #{ray_res[1][0].get_attribute(:rio_atts,'wall_block')}"
                            input_face.pushpull(distance, true)
                        end
                    end
                end
                Sketchup.active_model.entities.each{|ent| post_entities << ent}
            end

            
            # if reverse_ray_res
                # distance = reverse_ray_res[0].distance(face_center)
                # puts "reverse ray distance : #{distance}"
                # if distance > 60.mm
                    # if ray_res[1][0].get_attribute(:rio_atts,'wall_block')
                        # puts "Rev ray res : #{ray_res} : #{ray_res[1][0].get_attribute(:rio_atts,'wall_block')}"
                        # input_face.pushpull(distance, true)
                    # end
                # end
            # end
        end
    end
end
