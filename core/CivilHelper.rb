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
            puts "find_edges : #{sel_edge} : #{sel_face}"
            #sel.add(sel_edge)
            #sel.add(sel_face)

            edge_arr = []
            sel_edge.vertices.each{|ver|
                #puts ver.edges&sel_face.edges
                common_edges = ver.edges&sel_face.edges
                edge_arr << common_edges
            }
            edges = edge_arr.flatten!
            edges = edges.uniq!
            edges = edges - [sel_edge]
            edges.select!{|ed| ed.layer.name!='RIO_Column'}
            #sel.clear
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

            #puts "get_views : #{floor_edges_arr}"
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
            #puts "floor_edge_arr : #{floor_edge_arr}"
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

                if !distance1.nil?&!distance2.nil?
                    beam_wall_block = distance1<distance2 ? test1_item[0] : test2_item[0]  
                end
                if distance1.nil?
                    beam_wall_block = test2_item[1][0]
                elsif distance2.nil?
                    beam_wall_block = test1_item[1][0]
                end
            end

            if beam_wall_block.nil?
                puts "Could not identify where the beam starts from. Please draw the face on some wall or column."
                return false
            else
                room_name = beam_wall_block.get_attribute(:rio_block_atts, 'room_name')
                view_name = beam_wall_block.get_attribute(:rio_block_atts, 'view_name')
                start_block_id = beam_wall_block.persistent_id
            end
            
            block_vector = beam_wall_block.get_attribute :rio_block_atts, 'towards_wall_vector'
            input_face.reverse! if input_face.normal != block_vector #Instead reversing the normal
            
            face_center = input_face.bounds.center
            fnorm 		= input_face.normal
            #fnorm.reverse! if input_face.normal != block_vector

            beam_hit_found = false
            distance = 0.mm

            start_pts = [face_center]
            input_face.vertices.each { |face_vertex|
                face_point = face_vertex.position
                center_vector = face_point.vector_to(face_center)
                start_pt = face_point.offset(center_vector, 10.mm)
                start_pts << start_pt
            }
            start_pts.flatten!
            start_pts.uniq! #Not needed

            beam_components = Sketchup.active_model.entities.select{|ent| ent.layer.name=='RIO_Civil_Beam'}
            beam_components.each{|ent| ent.hidden=true}

           

            beam_algorithm = 2
            case beam_algorithm
            when 1

                #   First finish checking all opposite walls
                #   This algorithm follows below
                # - Hide all beams and columns except corner columns.
                # - Take 5 pts on the face and find a point each offset at 10mm to the center-- To avoid the overlap on the corners
                # - When u find a point hitting the wall or the corner column stop.
                allowed_intersections = ['column', 'wall']
                
                column_components = Sketchup.active_model.entities.select{|ent| ent.layer.name=='RIO_Civil_Column'}
                column_components.each{|ent| ent.hidden=true unless ent.get_attribute(:rio_block_atts, 'corner_column_flag')}

                start_pts.each { |start_pt|
                    start_pt = start_pt.position if start_pt.is_a?(Sketchup::Vertex)
                    hit_point, hit_item     = Sketchup.active_model.raytest(start_pt, fnorm)
                    if hit_item && hit_item[0].is_a?(Sketchup::ComponentInstance)
                        block_type = hit_item[0].get_attribute(:rio_block_atts, 'block_type')
                        if block_type && allowed_intersections.include?(block_type)
                            beam_hit_found = hit_item[0]
                            distance = start_pt.distance(hit_point)
                            break
                        end
                    end
                }
                puts "beam_components : #{beam_components}"
                puts "column components : #{column_components}"

                column_components.each{|ent| ent.hidden=false}
            when 2
                beam_length = 0
                start_pts.each { |start_pt|
                    start_pt = start_pt.position if start_pt.is_a?(Sketchup::Vertex)
                    last_point, hit_entity = find_last_hit_point start_pt, fnorm, room_name
                    if last_point
                        offset_distance = last_point.distance start_pt
                        if offset_distance > beam_length
                            beam_hit_found = hit_entity
                            beam_length = offset_distance 
                        end
                    end
                }
            end
            beam_components.each{|ent| ent.hidden=false}

            puts "beam_wall_block : #{beam_wall_block} : #{beam_hit_found}"
            puts "beam_hit_found : #{beam_hit_found} at distance #{beam_length}"
            sel.add(beam_wall_block)
            sel.add(beam_hit_found)
            if beam_wall_block == beam_hit_found
                beam_components.each{|ent| ent.hidden=false}
                column_components.each{|ent| ent.hidden=false}
                create_beam input_face
            else
                if beam_hit_found
                    input_face.set_attribute(:rio_block_atts, 'beam_face', 'true')
                    input_face.set_attribute(:rio_block_atts, 'room_name', room_name) 
                    input_face.set_attribute(:rio_block_atts, 'view_name', view_name)
                    input_face.set_attribute(:rio_block_atts, 'block_type', 'face')

                    input_face.edges.each { |i_edge|
                        i_edge.set_attribute(:rio_block_atts, 'beam_edge', 'true')
                        i_edge.set_attribute(:rio_block_atts, 'room_name', room_name) 
                        i_edge.set_attribute(:rio_block_atts, 'view_name', view_name)
                        i_edge.set_attribute(:rio_block_atts, 'block_type', 'edge')
                    }

                    pre_entities = Sketchup.active_model.entities.to_a
                    input_face.pushpull(beam_length, true)
                    post_entities = Sketchup.active_model.entities.to_a
                    new_entities 	= post_entities - pre_entities
                    temp_group 		= Sketchup.active_model.entities.add_group(new_entities)
                    Sketchup.active_model.layers.add('RIO_Civil_Beam') if Sketchup.active_model.layers['RIO_Civil_Beam'].nil?
                    temp_group.layer = Sketchup.active_model.layers['RIO_Civil_Beam']
                    beam_component = temp_group.to_component
                    
                    beam_component.set_attribute(:rio_block_atts, 'block_type', 'beam')
                    beam_component.set_attribute(:rio_block_atts, 'view_name', view_name)
                    beam_component.set_attribute(:rio_block_atts, 'face_id', input_face.persistent_id)
                    beam_component.set_attribute(:rio_block_atts, 'room_name', room_name)
                    beam_component.set_attribute(:rio_block_atts, 'beam_length', beam_length)
                    beam_component.set_attribute(:rio_block_atts, 'start_block', start_block_id)
                    beam_component.set_attribute(:rio_block_atts, 'end_block', beam_hit_found.persistent_id)
                    return beam_component
                else
                    puts "No opposite Wall found.Cannot draw Beam"
                    return false
                end

                # if false
                #     ray_res 		= Sketchup.active_model.raytest(face_center, fnorm)
                #     reverse_ray_res = Sketchup.active_model.raytest(face_center, fnorm.reverse)
                    
                #     puts "ray_res : #{ray_res}"
                #     #puts "reverse ray : #{reverse_ray_res}"
                    
                #     pre_entities = []; post_entities=[];
                #     Sketchup.active_model.entities.each{|ent| pre_entities << ent}
                #     if ray_res
                #         distance = ray_res[0].distance(face_center)
                #         puts "ray distance : #{distance}"
                #         if distance > 60.mm
                #             if ray_res[1][0].get_attribute(:rio_atts,'wall_block')
                #                 puts "ray res : #{ray_res} : #{ray_res[1][0].get_attribute(:rio_atts,'wall_block')}"
                #                 input_face.pushpull(distance, true)
                #             end
                #         end
                #     end
                #     Sketchup.active_model.entities.each{|ent| post_entities << ent}
                # end

                
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

        def self.get_room_entities room_name
            entities_array = []
            entities_array << Sketchup.active_model.entities.select{|ent| ent.get_attribute(:rio_block_atts, 'room_name')==room_name}
            entities_array.flatten!
            entities_array
        end

        def self.remove_room_entities room_name=nil
            unless room_name
                puts "Room name cannot be empty"
                return false
            end
            puts "Room to be deleted : ++#{room_name}++"
            room_entities = get_room_entities(room_name)
            if room_entities.empty?
                puts "Nothing to remove"
            else
                wall_entities   = room_entities.select{|ent| ent.get_attribute(:rio_block_atts, 'block_type')=='wall'}
                door_entities   = room_entities.select{|ent| ent.get_attribute(:rio_block_atts, 'block_type')=='door'}
                window_entities = room_entities.select{|ent| ent.get_attribute(:rio_block_atts, 'block_type')=='window'}
                column_entities = room_entities.select{|ent| ent.get_attribute(:rio_block_atts, 'block_type')=='column'}
                beam_entities   = room_entities.select{|ent| ent.get_attribute(:rio_block_atts, 'block_type')=='beam'}
                face_entities   = room_entities.select{|ent| ent.get_attribute(:rio_block_atts, 'block_type')=='face'}
                edge_entities   = room_entities.select{|ent| ent.get_attribute(:rio_block_atts, 'block_type')=='edge'}

                puts "-----------------Room entities --------------------------------"
                puts "Wall                      : #{wall_entities.length}"
                puts "Door                      : #{door_entities.length}"
                puts "Window                    : #{window_entities.length}"
                puts "Column                    : #{column_entities.length}"
                puts "Beam                      : #{beam_entities.length}"
                puts "Face                      : #{face_entities.length}"
                puts "Edge                      : #{edge_entities.length}"
                puts "#{room_entities.length} #{room_name} entities have been deleted"
                Sketchup.active_model.entities.erase_entities(room_entities)
                
            end
            return true
        end
        
        # RIO::CivilHelper::find_last_hit_point fsel.center, X_AXIS, 'MBR'
        def self.find_last_hit_point input_pt, input_vector, room_name
            room_entities_a = get_room_entities room_name
            continue_raytest = true
            count = 1 #Just to avoid infinite loop
            allowed_intersections = ['column', 'wall']
            hidden_items = []
            hit_points_a = []
            puts "Room entities : #{room_entities_a}"

            while continue_raytest
                puts "Loop raytest : #{count}"
                hit_point, hit_item     = Sketchup.active_model.raytest(input_pt, input_vector)
                if hit_item && hit_item[0].is_a?(Sketchup::ComponentInstance)
                    hit_entity = hit_item[0]
                    puts "Comp : #{hit_entity}"
                    block_type = hit_entity.get_attribute(:rio_block_atts, 'block_type')
                    if room_entities_a.include?(hit_entity)
                        puts "Allowed entity #{hit_entity}"
                        if allowed_intersections.include?(block_type)
                            puts "Adding to hidden items : #{hit_entity}"
                            hidden_items << hit_entity
                            hit_points_a << hit_point
                            hit_entity.hidden = true
                        else
                            puts "This is not a valid room entity where the beam can finish."
                            return nil
                        end
                    else
                        puts "Unallowed enity : #{hit_entity}"
                        continue_raytest = false
                    end
                else
                    puts "Nothing hit.Stopping raytest"
                    continue_raytest = false
                end
                count = count+1
                continue_raytest = false if count > 20
            end
            hidden_items.each { |ent| ent.hidden=false}
            puts "hit_points : #{hit_points_a}"
            if hit_points_a.empty?
                puts "No valid entities found in raytest"
                return nil
            else
                return hit_points_a.last, hidden_items.last
            end
        end

        def self.perimeter_wall
            outer_walls = get_outer_walls
            wall_width 	= 30.mm 
            outer_walls.each { |wall_edge|
                verts = wall_edge.vertices
                
                clockwise = check_clockwise_edge wall_edge, wall_edge.faces[0]
                if clockwise
                    pt1, pt2 = verts[0].position, verts[1].position
                else
                    pt1, pt2 = verts[1].position, verts[0].position
                end
                if wall_edge.layer.name == 'RIO_Wall'
                    wall_inst = CivilHelper::place_cuboidal_component(pt2, pt1, comp_height: WALL_HEIGHT, comp_width: wall_width)
                elsif wall_edge.layer.name == 'RIO_Window'
                    #create_window window_edge, room_face, window_height, window_offset, wall_height
                end

            }
        end

        
        def self.create_single_column column_edge_arr, column_face=nil, wall_height=nil
            puts "create_single_column": #{column_edge_arr}
            intersect_pt 	    = nil
            corner_column_flag  = false
            input_face          = @room_face
            column_layer = Sketchup.active_model.layers['RIO_Column']

            
            column_edge_arr.each{|c_edge|
                puts "c_edge : #{c_edge.layer.name}"
                c_edge.layer=column_layer unless c_edge.layer.name=='RIO_Wall'
            }

            if column_face
                column_edge_arr.select!{|edge| edge.layer.name=='RIO_Column'}
                column_face.edges.each{|col_edge|
                    puts "col_edge.layer.name : #{col_edge.layer.name}"
                    if col_edge.layer.name == 'RIO_Column'
                        col_edge.faces.each{ |col_face|
                            input_face = col_face if col_face.get_attribute(:rio_atts, 'room_name') 
                        }
                    end        
                }
                if input_face
                    puts "Room Face is : #{input_face}"
                    wall_height = input_face.get_attribute(:rio_atts, 'wall_height')
                    room_name   = input_face.get_attribute(:rio_atts, 'room_name')
                else
                    puts "The room face could not be found"
                    return false
                end
            end

            case column_edge_arr.length
            when 1
                #Corner column with only one edge visible
                column_edge = column_edge_arr[0]
                adjacent_edges = CivilHelper::find_edges(column_edge_arr[0], input_face)
                intersect_pt = Geom.intersect_line_line(adjacent_edges[0].line, adjacent_edges[1].line)
                col_verts = column_edge.vertices
                column_face = Sketchup.active_model.entities.add_face(col_verts[0], col_verts[1], intersect_pt)
            when 2
                adjacent_edges = []
                column_edge_arr.each { |column_edge|
                    adjacent_edges << CivilHelper::find_edges(column_edge, input_face)
                }
                #puts "adj : #{adjacent_edges}"
                adjacent_edges.flatten!; adjacent_edges.uniq!
                view_name = []
                adjacent_edges.each{ |a_edge|
                    view_name << a_edge.get_attribute(:rio_edge_atts, 'view_name')
                }
                column_edge_arr.each { |column_edge|
                    column_edge.set_attribute(:rio_edge_atts, 'view_name', view_name)
                }
                intersect_pt = Geom.intersect_line_line(adjacent_edges[0].line, adjacent_edges[1].line)

                common_vertex = column_edge_arr[1].vertices&column_edge_arr[0].vertices
                vert_a = []
                vert_a << column_edge_arr[0].vertices-common_vertex
                vert_a << common_vertex
                vert_a << column_edge_arr[1].vertices-common_vertex
                vert_a << intersect_pt
                
                vert_a.flatten!; vert_a.uniq!

                pts_a = []; vert_a.each{|pt| 
                    pt = pt.position if pt.is_a?(Sketchup::Vertex)
                    pts_a <<  pt
                }
                #pts_a << intersect_pt; 
                pts_a.flatten!; pts_a.uniq!

                column_face = Sketchup.active_model.entities.add_face(pts_a)
                corner_column_flag = true
            when 3
                #This code has been written because the array of edges are not regular....They are not sorted sometimes.

                #Find the center edge
                center_index = 0 if (column_edge_arr[1].vertices&column_edge_arr[2].vertices).empty?
                center_index = 1 if (column_edge_arr[0].vertices&column_edge_arr[2].vertices).empty?
                center_index = 2 if (column_edge_arr[0].vertices&column_edge_arr[1].vertices).empty?
                arr = [0, 1, 2] - [center_index]
                center_edge = column_edge_arr[center_index]

                #Find the common vertex of side edges
                first_common_vertex = column_edge_arr[arr[0]].vertices&center_edge.vertices
                last_common_vertex  = column_edge_arr[arr[1]].vertices&center_edge.vertices

                #FInd the face points
                vert1 = column_edge_arr[arr[0]].vertices - [first_common_vertex[0]];vert1 = vert1[0].position
                vert2 = first_common_vertex.first.position
                vert3 = last_common_vertex.first.position
                vert4 = column_edge_arr[arr[1]].vertices - [last_common_vertex[0]];vert4 = vert4[0].position

                column_face = Sketchup.active_model.entities.add_face(vert1, vert2, vert3, vert4)
            when 4
                #Other columns
                adjacent_edges = []
                column_edge_arr.each { |column_edge|
                    if column_edge.layer.name == 'RIO_Column'
                        adjacent_edges << CivilHelper::find_edges(column_edge, input_face)
                    end
                }

                puts "adjacent edges : #{adjacent_edges}"
                if adjacent_edges
                    adjacent_edges.flatten!; adjacent_edges.uniq!
                    puts "post adjacent edges : #{adjacent_edges}"
                    sel.add(adjacent_edges)
                    if adjacent_edges.length == 2
                        intersect_pt = Geom.intersect_line_line(adjacent_edges[0].line, adjacent_edges[1].line)
                        adjacent_edges.each { |adj_edge|
                            common_vertex=nil
                            column_edge_arr.each { |col_edge|
                                common_vertex = (col_edge.vertices&adj_edge.vertices)[0]
                                if common_vertex && intersect_pt
                                    puts "intersect pt : #{intersect_pt} : #{common_vertex}"
                                    Sketchup.active_model.entities.add_line(intersect_pt, common_vertex.position)
                                    break
                                end
                            }
                        }
                        column_edge_arr.each {|column_edge|
                            column_edge.find_faces
                        }
                        faces = column_edge_arr[0].faces
                        column_edge_arr.each {|column_edge|
                            faces = faces&(column_edge.faces-[input_face])
                        }
                        column_face = faces[0]
                    else
                        puts "4 : Something wrong with the adjacent edges"
                    end
                end

            else
                puts "Column edges more than 4 not supported."
            end
            column_edge_arr.each {|column_edge|
                column_edge.find_faces
            }

            if column_face
                offset_pts = []
                column_face.edges.each{ |edge|
                    edge.layer.name='RIO_Wall' if edge.layer.name != 'RIO_Column'
                }
                column_face.vertices.each{|vert|
                    offset_pts << vert.position.offset(Z_AXIS, wall_height)
                }
                prev_ents = Sketchup.active_model.entities.to_a
                new_face = Sketchup.active_model.entities.add_face(offset_pts)
                puts "new_face normal : #{new_face.normal}"
                new_face.reverse! if new_face.normal.z < 0
                new_face.pushpull -(wall_height-1.mm)
                curr_ents = Sketchup.active_model.entities.to_a
                puts "new_face normal after: #{new_face.normal}"
                new_ents = curr_ents - prev_ents
                column_group = Sketchup.active_model.entities.add_group(new_ents)
                column_group.layer = Sketchup.active_model.layers['RIO_Civil_Column']
                comp_inst = column_group.to_component
                
                #Set attributes
                view_name = column_edge_arr[0].get_attribute(:rio_edge_atts, 'view_name') unless view_name
                comp_inst.set_attribute(:rio_block_atts, 'corner_column_flag', corner_column_flag)
                comp_inst.set_attribute(:rio_block_atts, 'block_type', 'column')
                comp_inst.set_attribute(:rio_block_atts, 'view_name', view_name)
                comp_inst.set_attribute(:rio_block_atts, 'edge_id', column_edge_arr[0].persistent_id)
                comp_inst.set_attribute(:rio_block_atts, 'room_name', room_name)
                comp_inst.set_attribute(:rio_block_atts, 'wall_block', 'true')
                return comp_inst
            end
            return nil
        end

    end
end
