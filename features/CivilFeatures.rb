rioload_ruby '/core/CivilComponent'
rioload_ruby '/core/SketchupHelper'

module RIO
    module CivilMod
        class RoomWall < CivilComponent
            def initialize(pname='', pheight=0, pwidth=0, pdepth=0, pcolor='')
                @height = 'white'
            end
            def get_selfname
                @height
            end
        end

        class RoomFloor < CivilComponent
            #RoomFloor types
            TRIANGLE                    = 1
            RECTANGLE                   = 2
            PERP_POLYGON                = 3

            #Irregular
            QUADRILATERAL               = 4
            SINGLE_SLOPE_POLYGON        = 5
            MULTI_SLOPE_POLYGON         = 6

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
    end
end