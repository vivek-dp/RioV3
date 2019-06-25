rioload_ruby '/core/CivilComponent'
rioload_ruby '/core/SketchupHelper'
rioload_ruby '/core/CivilHelper'

#rioload_ruby '/core/'

module RIO
    module CivilMod
        class RoomFloor < CivilComponent

            def initialize(selectedface, name='', floorcolor='')
                @nativeface = selectedface
                @name       = name
                @color      = floorcolor
            end

            #---------------------------------------------------------------------------------------
            # Find adjacent edge of the door
            #---------------------------------------------------------------------------------------
            def find_door_adjacent_edges native_face
                face_normal = native_face.normal
                edges = native_face.edges
                edges << edges[0]

                wall_settings = $RIO_SET[:ANALYSIS]['civil_settings']['Wall']
                wall_min_length = wall_settings['Length_minimum'] #Better change at the settings level
                wall_max_length = wall_settings['Length_maximum']+1


                edges.each { | face_edge |
                    if face_edge.layer.name == 'RIO_Door'
                        door_adj_edges = SketchupHelper::get_adjacent_edges face_edge, native_face
                        door_adj_edges.each { |adj_edge|
                            adj_length = adj_edge.length
                            angle = SketchupHelper::angle_between_face_edges face_edge, adj_edge, native_face.normal
                            puts "Details : #{angle.radians.round}, #{adj_length}, #{wall_min_length}, #{wall_max_length}"

                            if angle.radians.round == 90 && adj_length < wall_max_length
                                puts "Angle is 90 and length less"
                                adj_edge.set_attribute(:rio_atts, 'wall_adjacent_edge', 'true')
                            end
                        }
                    end
                }
            end

            #   Description : This function will identify the type of the polygon the floor is...
            #   1. Find the door edges first.
            #   2. Ignore the walls near the door edge - 
            #   3. 

            def same_vector edge1, edge2
                zero_vector = Geom::Vector3d.new(0,0,0)
                if edge1.line[1] == edge2.line[1]
                    return true
                elsif (edge1.line[1]*edge2.line[1])==zero_vector
                    return true
                end
                return false
            end

            def get_room_poly_type
                face_normal = @native_face.normal
                edges = @native_face.edges
                
                # Find the door adjacent edges and eliminate them.
                find_door_adjacent_edges
                
                # Remove the door and adjacent edges.
                edges.each{ |i_edge|
                    adj_edge = i_edge.get_attribute(:rio_atts, 'wall_adjacent_edge') 
                    remaining_edges << i_edge if (i_edge.layer.name=='RIO_Door' || adj_edge)
                }
                remaining_edges << remaining_edges[0]
                
                #remaining_edges = fsel.edges
                total_edges = remaining_edges.length

                remaining_edges.each{ |curr_edge|
                    next_edge = remaining_edges[1]
                    remaining_edges.rotate! 
                    break if same_vector(curr_edge, next_edge)
                }

                count = 1; wall = {};
                view_name       = 'view_%d'%[count]
                prev_edge       = remaining_edges[0]
                wall[ ] = [prev_edge]

                remaining_edges[1..total_edges].each { |curr_edge|
                    if same_vector(prev_edge, curr_edge)
                        wall[view_name] = [] unless wall[view_name]
                        wall[view_name] << curr_edge
                    else
                        count += 1
                        view_name       = 'view_%d'%[count]
                        wall[view_name] = [curr_edge]
                    end
                    prev_edge = curr_edge
                }


                #Get the edge pairs for finding angles...
                edge_pairs = []
                remaining_edges[0..-2].each_with_index{|e,i|
                    edge_pairs << [e,remaining_edges[i+1]]
                }


                edge_pairs.each{ |pair|
                    angle = SketchupHelper::angle_between_face_edges edge1, edge2, face_normal                    
                }
            end

            def run_perimeter_analysis 
                RIODEBUG("Start perimeter analysis : #{@native_face.edges}")

                #Find the room type
                room_poly_type = get_room_poly_type
            end

            def check_perpendicular_edges input_face
                return false if input_face.nil?
                edges = input_face.edges
                edges.length.times do |index|
                    edges
                end
            end

            def find_room_type selected_face
            end
        end

        class Door < CivilComponent

        end

        class Window < CivilComponent

        end
        class Beam < CivilComponent

        end
        class Column < CivilComponent

        end
        class Skirting < CivilComponent

        end
        class CounterTop < CivilComponent

        end
=begin
wall_obj = RIO::CivilMod::RoomWall.new(:wall_edge=>fsel,
                :wall_face=>fp,
                :wall_height=>500.mm,
                :room_name=>'test11'
)
=end
        class RoomWall < CivilComponent
            attr_accessor :wall_defn, :wall_edge, :wall_face, :wall_height, :room_name
            def initialize(params = {})
                @wall_edge = params[:wall_edge]
                @wall_face = params[:wall_face]
                @wall_height = params[:wall_height]
                @room_name = params[:room_name]
                create_wall_defn
            end

            def create_wall_defn
                puts "create wall defn called"
                wall_width = 50.mm
                @wall_defn = CivilHelper::create_cuboidal_entity @wall_edge.length, wall_width, @wall_height
            end
        end

        class PolyRoom < CivilComponent
            attr_accessor :room_name, :wall_height, :wall_color,
                            :door_height, :window_height, :window_offset

            def initialize( params = {})
                args = method(__method__).parameters.map { |arg| arg[1].to_s }
                puts "Room Initialization.. \n"+ args.map { |arg| "Inputs #{arg} = #{eval arg}" }.join('\n')

                @room_name      = params[:room_name]
                @wall_height    = params[:wall_height].to_f if params[:wall_height]
                @door_height    = params[:door_height].to_f if params[:door_height]
                @window_height  = params[:window_height].to_f if params[:window_height]
                @window_offset  = params[:window_offset].to_f if params[:window_offset]
                @wall_color     = params[:wall_color].nil? ? 'white' : params[:wall_color]

                @room_face      = Sketchup.active_model.selection[0]
                unless @room_face.is_a?(Sketchup::Face)
                    raise ArgumentError.new("The selection is not a face")
                    return false   
                end

                puts "HHH : #{window_height} : #{wall_height} : #{door_height} : #{window_offset}"
                CivilHelper.add_wall_corner_lines
                room_views_a = CivilHelper.get_wall_views @room_face

                count = 0
                room_views_a.each do |edge_arr|
                    count += 1
                    wall_view_name = room_name+'_V_'+count.to_s
                    edge_arr.each{|v_edge| v_edge.set_attribute(:rio_edge_atts, 'view_name', wall_view_name)}
                end
                construct_poly_room
            end
            
            def construct_poly_room
                if room_name.nil? || room_name.empty?
                    raise ArgumentError.new("Room name is mandatory")
                    return false
                end

                if wall_height.nil? || wall_height < 1.mm
                    raise ArgumentError.new("Wall height is necessary")
                    return false
                end 

                room_edges = @room_face.outer_loop.edges

                room_edges.each { |r_edge|
                    case r_edge.layer.name
                    when 'RIO_Window'
                        if window_height.nil? || window_height < 1.mm
                            raise ArgumentError.new("Window height is necessary")
                            return false
                        end 
                        if window_offset.nil? || window_offset < 1.mm
                            raise ArgumentError.new("Window Offset is necessary")
                            return false
                        end
                    end
                }

                puts "Starting room construction : Time #{Time.now}"
                create_poly_room
                puts "Finishing room construction : Time #{Time.now}"
            end

            def create_poly_room
                Sketchup.active_model.layers.add('RIO_Civil_Wall') if Sketchup.active_model.layers['RIO_Civil_Wall'].nil?
                room_wall_edges = @room_face.edges.select{|edge| edge.layer.name == 'RIO_Wall'} 
                room_wall_edges.each{ |wall_edge|
                    #next
                    verts = wall_edge.vertices
                    
                    clockwise = CivilHelper::check_clockwise_edge wall_edge, @room_face
                    if clockwise
                        pt1, pt2 = verts[0].position, verts[1].position
                    else
                        pt1, pt2 = verts[1].position, verts[0].position
                    end
                    
                    towards_wall_vector = CivilHelper::check_edge_vector wall_edge, @room_face

                    wall_inst = CivilHelper::place_cuboidal_component(pt1, pt2, comp_height: @wall_height)
                    developer_mode = true
                    if developer_mode
                        wall_inst.material = Sketchup::Color.names[rand(140)]
                    else
                        wall_inst.material = @wall_color
                    end
                    view_name = wall_edge.get_attribute(:rio_edge_atts, 'view_name')

                    wall_inst.set_attribute(:rio_block_atts, 'block_type', 'wall')
                    wall_inst.set_attribute(:rio_block_atts, 'wall_type', 'normal')
                    wall_inst.set_attribute(:rio_block_atts, 'edge_id', wall_edge.persistent_id)
                    wall_inst.set_attribute(:rio_block_atts, 'view_name', view_name)
                    wall_inst.set_attribute(:rio_block_atts, 'wall_block', 'true')
                    wall_inst.set_attribute(:rio_block_atts, 'start_point', pt1)
                    wall_inst.set_attribute(:rio_block_atts, 'end_point', pt2)
                    wall_inst.set_attribute(:rio_block_atts, 'wall_height', wall_height)
                    wall_inst.set_attribute(:rio_block_atts, 'room_name', room_name)
                    wall_inst.set_attribute(:rio_block_atts, 'towards_wall_vector', towards_wall_vector) #Will used for beam

                    wall_inst.layer = Sketchup.active_model.layers['RIO_Civil_Wall']
                }

                door_edges = @room_face.edges.select{|e| e.layer.name == 'RIO_Door'}
                if door_edges.length > 0
                    door_edges.each{ |door_edge|
                        puts "Door : #{door_edge}"
                        create_door door_edge, @room_face, door_height, wall_height
                    }
                    puts "Room Doors created"
                end

                #------------------------------------------
                window_edges = @room_face.edges.select{|e| e.layer.name == 'RIO_Window'}
                if window_edges.length > 0
                    window_edges.each{ |window_edge|
                        puts "Window : #{window_edge}"
                        create_window window_edge, @room_face, window_height, window_offset, wall_height
                    }
                    puts "Room Windows created"
                end

                #------------------------------------------
                column_edges = @room_face.edges.select{|e| e.layer.name == 'RIO_Column'}
                if column_edges.length > 0
                    column_inst = create_columns @room_face, wall_height
                    puts "Columns created"
                end

            end #create_polyroom

            def create_door door_edge, room_face, door_height, wall_height
                room_edges 		= room_face.edges
                adjacent_edges 	= []

                if door_height > wall_height
                    puts "Door height cannot be greater than wall height : #{door_height} : #{wall_height}"
                    return
                end

                #Find the adjacent perpendicular edges...90 degrees not 180,270
                room_edges.each{|redge|
                    unless (redge.vertices&door_edge.vertices).empty?
                        angle = door_edge.line[1].angle_between redge.line[1]
                        adjacent_edges << redge if(angle.ceil(2)==(Math::PI/2).ceil(2))
                    end
                }
                if adjacent_edges.empty?
                    puts "Door Wall Error: No Perpendicular Adjacent edges found"
                    return
                end
                #----------------------------------------------------------------

                #Find edges less than 251 mm...greater than check not added now....
                adjacent_edges.select!{|ad_edge| ad_edge.length < 251.mm}
                if adjacent_edges.empty?
                    puts "Door Wall Error : Perpendicular edges are longer than 251mm"
                    return
                else
                    puts "adjacent_edges : #{adjacent_edges}"
                    adjacent_edges.each{|adj_edge| adj_edge.set_attribute(:rio_atts, 'door_adjacent', door_edge.persistent_id)}
                end

                #Sort the length...descending
                adjacent_edges.sort_by!{|ad_edge| -ad_edge.length}
                adjacent_edge = adjacent_edges[0]
                verts = door_edge.vertices
                entity_width = adjacent_edge.length

                clockwise = CivilHelper::check_clockwise_edge door_edge, room_face
                if clockwise
                    pt1, pt2 = verts[0].position, verts[1].position
                else
                    pt1, pt2 = verts[1].position, verts[0].position
                end

                door_block_height = wall_height - door_height
                door_wall_inst = CivilHelper::place_cuboidal_component(pt2, pt1, comp_width: entity_width, comp_height: door_block_height, at_offset: door_height)

                view_name = door_edge.get_attribute(:rio_edge_atts, 'view_name')
                room_name = view_name.split('_V_')[0]
                towards_wall_vector = CivilHelper::check_edge_vector door_edge, @room_face

                door_wall_inst.set_attribute(:rio_block_atts, 'wall_type', 'door_wall')
                door_wall_inst.set_attribute(:rio_block_atts, 'edge_id', door_edge.persistent_id)
                door_wall_inst.set_attribute(:rio_block_atts, 'view_name', view_name)
                door_wall_inst.set_attribute(:rio_block_atts, 'wall_block', 'true')
                door_wall_inst.set_attribute(:rio_block_atts, 'start_point', pt1)
                door_wall_inst.set_attribute(:rio_block_atts, 'end_point', pt2)
                door_wall_inst.set_attribute(:rio_block_atts, 'wall_height', door_block_height)
                door_wall_inst.set_attribute(:rio_block_atts, 'room_name', room_name)
                door_wall_inst.set_attribute(:rio_block_atts, 'towards_wall_vector', towards_wall_vector) #Will used for beam

                add_real_door = true
                if add_real_door
                    puts "Adding Real Door to the opening"
                    door_skp = RIO_ROOT_PATH+'/assets/samples/Door.skp'
                    door_defn = Sketchup.active_model.definitions.load(door_skp)

                    realdoor_inst 		= Sketchup.active_model.entities.add_instance door_defn, ORIGIN
                    door_bbox 	= realdoor_inst.bounds

                    x_factor 	= door_edge.length / door_bbox.width
                    y_factor 	= entity_width / door_bbox.height
                    z_factor	= door_height / door_bbox.depth

                    puts "factors : #{x_factor} : #{y_factor} : #{z_factor}"
                    realdoor_inst.transform!(Geom::Transformation.scaling(x_factor, y_factor, z_factor))
                    realdoor_inst.transform!(Geom::Transformation.new(pt2))

                    extra = 0
                    #Rotate instance
                    trans_vector = pt2.vector_to(pt1)
                    if trans_vector.y < 0
                        trans_vector.reverse!
                        extra = Math::PI
                    end
                    angle 	= extra + X_AXIS.angle_between(trans_vector)
                    puts "door angle : #{angle} : #{trans_vector}"
                    realdoor_inst.transform!(Geom::Transformation.rotation(pt2, Z_AXIS, angle))

                    realdoor_inst.set_attribute(:rio_block_atts, 'edge_id', door_edge.persistent_id)
                    realdoor_inst.set_attribute(:rio_block_atts, 'view_name', view_name)
                    realdoor_inst.set_attribute(:rio_block_atts, 'wall_block', 'false')
                    realdoor_inst.set_attribute(:rio_block_atts, 'start_point', pt1)
                    realdoor_inst.set_attribute(:rio_block_atts, 'end_point', pt2)
                    realdoor_inst.set_attribute(:rio_block_atts, 'door_height', door_height)
                    realdoor_inst.set_attribute(:rio_block_atts, 'room_name', room_name)
                    return [door_wall_inst, realdoor_inst]
                end
                return [door_wall_inst]
            end

            def create_window window_edge, room_face, window_height, window_offset, wall_height
                room_edges = room_face.edges
                verts      = window_edge.vertices

                adjacent_edges = []

                if (window_height+window_offset) > wall_height
                    puts "Window height hits the roof : H - #{window_height} : O - #{window_offset} WH - #{wall_height}"
                    return
                end

                clockwise = CivilHelper::check_clockwise_edge window_edge, room_face
                if clockwise
                    pt1, pt2 = verts[0].position, verts[1].position
                else
                    pt1, pt2 = verts[1].position, verts[0].position
                end

                top_wall_at_height 		= (window_height + window_offset)
                top_wall_block_height 	= wall_height -  top_wall_at_height

                CivilHelper::place_cuboidal_component(pt1, pt2, comp_height: window_offset)
                CivilHelper::place_cuboidal_component(pt1, pt2, comp_height: top_wall_block_height, at_offset: top_wall_at_height)


                add_real_window = true
                if add_real_window
                    puts "add_real_door"
                    window_skp = RIO_ROOT_PATH+'/assets/samples/Window.skp'
                    window_defn = Sketchup.active_model.definitions.load(window_skp)

                    inst 		= Sketchup.active_model.entities.add_instance window_defn, ORIGIN
                    window_bbox 	= inst.bounds

                    x_factor 	= window_edge.length / window_bbox.width
                    y_factor 	= 50.mm / window_bbox.height
                    z_factor	= window_height / window_bbox.depth

                    puts "factors : #{x_factor} : #{y_factor} : #{z_factor}"
                    inst.transform!(Geom::Transformation.scaling(x_factor, y_factor, z_factor))

                    wpt1, wpt2 = pt1, pt2
                    wpt1.z	=	window_offset
                    wpt2.z 	= 	window_offset
                    inst.transform!(Geom::Transformation.new(wpt1))
                    extra = 0
                    #Rotate instance
                    trans_vector = wpt1.vector_to(wpt2)
                    if trans_vector.y < 0
                        trans_vector.reverse!
                        extra = Math::PI
                    end
                    angle 	= extra + X_AXIS.angle_between(trans_vector)
                    puts "Window angle : #{angle} : #{trans_vector}"
                    inst.transform!(Geom::Transformation.rotation(wpt1, Z_AXIS, angle))
                end

                #Check if the window is an external window
                create_external_window = true
                if create_external_window
                    window_face 	= window_edge.faces
                    window_face.delete room_face
                    if window_face.one?
                        window_face = window_face[0]
                        window_face_arr = CivilHelper::find_adj_window_face [window_face]
                        external_face = window_face_arr.last
                        external_edge = external_face.edges.select{|ed| ed.faces.length == 1}[0]
                        if external_edge.layer.name == 'RIO_Window'
                            puts "Its an external window. Adding the wall for the external edge."
                            clockwise 	= CivilHelper::check_clockwise_edge external_edge, external_face
                            verts 		= external_edge.vertices
                            if clockwise
                                pt1, pt2 = verts[0].position, verts[1].position
                            else
                                pt1, pt2 = verts[1].position, verts[0].position
                            end

                            CivilHelper::place_cuboidal_component(pt2, pt1, comp_height: window_offset)
                            CivilHelper::place_cuboidal_component(pt2, pt1, comp_height: top_wall_block_height, at_offset: top_wall_at_height)
                        else
                            puts "One external edge found. But its layer is not window layer"
                        end
                    else
                        puts "Window is not a proper external window"
                    end
                end

            end

            def create_columns input_face, wall_height
                #input_face = fsel
                puts "Input face : #{input_face}"

                Sketchup.active_model.layers.add('RIO_Civil_Column') if Sketchup.active_model.layers['RIO_Civil_Column'].nil?

                #Working on the outer loop of the floor....
                outer_columns = []
                outer_loop_flag = true
                if outer_loop_flag
                    face_edges = input_face.outer_loop.edges
                    wall_layers = ['RIO_Wall', 'RIO_Window', 'RIO_Door']
                    face_edges.length.times do
                        f_edge = face_edges[0]
                        break if f_edge.layer.name != 'RIO_Column'
                        face_edges.rotate!
                    end

                    columns = []
                    column_edges = []
                    face_edges.each{ |f_edge|
                        if f_edge.layer.name == 'RIO_Column'
                            column_edges << f_edge
                        else
                            columns << column_edges unless column_edges.empty?
                            column_edges = []
                        end
                    }

                    #puts "columns : #{columns.length} : #{columns}"
                    columns.each { |column_edge_arr|
                        intersect_pt 	= nil
                        column_face		= nil
                        corner_column_flag = false

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
                                adjacent_edges << CivilHelper::find_edges(column_edge, input_face)
                            }

                            if adjacent_edges
                                adjacent_edges.flatten!; adjacent_edges.uniq!
                                if adjacent_edges.length == 2
                                    intersect_pt = Geom.intersect_line_line(adjacent_edges[0].line, adjacent_edges[1].line)
                                    adjacent_edges.each { |adj_edge|
                                        common_vertex=nil
                                        column_edge_arr.each { |col_edge|
                                            common_vertex = (col_edge.vertices&adj_edge.vertices)[0]
                                            if common_vertex
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

                        # if column_face
                        #     prev_ents = [];Sketchup.active_model.entities.each{|ent| prev_ents << ent}

                        #     # if input_face.normal.z < 0
                        #     #     wall_height = -wall_height
                        #     # end
                        #     column_face.reverse! if column_face.normal.z > 0
                        #     puts "Columns : #{column_face.normal.z} : #{wall_height}"
                        #     column_face.pushpull(wall_height, true)
                        #     curr_ents = [];Sketchup.active_model.entities.each{|ent| curr_ents << ent}
                        #     new_ents = curr_ents - prev_ents
                        #     column_group = Sketchup.active_model.entities.add_group(new_ents)
                        #     column_group.layer = Sketchup.active_model.layers['RIO_Civil_Column']
                        #   comp_inst = column_group.to_component
                        #   end

                        if column_face
                            offset_pts = []
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
                            view_name = column_edge_arr[0].get_attribute(:rio_edge_atts, 'view_name')
                            comp_inst.set_attribute(:rio_block_atts, 'corner_column_flag', corner_column_flag)
                            comp_inst.set_attribute(:rio_block_atts, 'block_type', 'column')
                            comp_inst.set_attribute(:rio_block_atts, 'view_name', view_name)
                            comp_inst.set_attribute(:rio_block_atts, 'edge_id', column_edge_arr[0].persistent_id)
                            
                        end
                        outer_columns << comp_inst
                    }
                end

                inner_loop_flag  	= true
                if inner_loop_flag
                    inner_loops 	= input_face.loops - [input_face.outer_loop]
                    puts "inner loops : #{inner_loops}"
                    inner_loops.each {|iloop|
                        column_face_flag = true
                        loop_faces = []
                        iloop.edges.each{|iedge|
                            column_face_flag = false unless iedge.layer.name.start_with?('RIO_Column')
                            loop_faces << iedge.faces
                        }
                        if column_face_flag
                            #Find the face of the loop.
                            loop_faces.flatten!
                            loop_faces = loop_faces - [input_face]
                            loop_faces.flatten!
                            loop_faces.uniq!

                            #Do usual pull push upto wall height
                            column_face = loop_faces[0]
                            # prev_ents = [];Sketchup.active_model.entities.each{|ent| prev_ents << ent}
                            # column_face.reverse! if column_face.normal.z > 0
                            # column_face.pushpull(wall_height, true)
                            # curr_ents = [];Sketchup.active_model.entities.each{|ent| curr_ents << ent}
                            # new_ents = curr_ents - prev_ents
                            # column_group = Sketchup.active_model.entities.add_group(new_ents)
                            # column_group.layer = Sketchup.active_model.layers['RIO_Civil_Column']

                            offset_pts = []
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
                        end
                    }
                end
            end

        end #Class PolyRoom
    end
end

=begin

ob = RIO::CivilMod::PolyRoom.new(  :room_name=>'rnam1',
                            :wall_height=>3000.mm, 
                            :wall_color=>'blue',
                            :door_height=>2000.mm, 
                            :window_height=>800.mm, 
                            :window_offset=>1000.mm)  

=end