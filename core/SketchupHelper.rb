module RIO
    module SketchupHelper
        def self.check_perpendicular edge1, edge2
            angle 	= edge1.line[1].angle_between edge2.line[1] 
            angle 	= angle*(180/Math::PI)
            return true if angle.round == 90
            return false
        end

        #Angle between the edges with repsect to the face.
        def self.angle_between_face_edges edge1, edge2, normal
            valid_edges = false
            if edge1 && edge1.is_a?(Sketchup::Edge)
                if edge2 && edge2.is_a?(Sketchup::Edge)
                    if normal && normal.is_a?(Geom::Vector3d)
                        valid_edges = true 
                    end
                end
            end
            if valid_edges
                vector1 = edge1.line[1]
                vector2 = edge2.line[1]
                cross = vector1 * vector2
                direction = cross % normal
                angle = vector1.angle_between( vector2 )
                angle = 360.degrees - angle if direction > 0.0
                return angle
            end
            RIODEBUG("Invalid parameters : angle_between_face_edges #{edge1} : #{edge2} : #{normal}")
            return false
        end

        #Method to get the adjacent edges of the edge within the face
        def self.get_adjacent_edges input_edge, input_face 
            adjacent_edges  = []
            iedge_vertices  = input_edge.vertices
            other_edges     = input_face.edges - [input_edge]
            other_edges.each { |oedge|
                adjacent_edges << oedge if(oedge.vertices && iedge_vertices)
            }
            return adjacent_edges
        end

        
    end # SketchupHelper
end # RIO