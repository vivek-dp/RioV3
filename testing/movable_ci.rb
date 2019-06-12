# movable_ci.rb - a ComponentInstance with easy, move!-based transformations
# from Edges to Rubies - The Complete SketchUp Tutorial
# Copyright 2010, Martin Rinehart

require 'sketchup'

class MovableCI
=begin
A MovableCI can do move, rotate and scale transformations. The developer 
creates a MovableCI from a ComponentInstance and then applies move(), 
rotate() and/or scale() methods directly, without needing Transformation 
objects or methods.

Internally, the transformations are performed with the 
ComponentInstance.move!() method, not recording changes on the undo stack 
and not invalidating the view. (Use a TransformableCI if you want to record 
undo changes and see changes immediately.)

This is documented in the tutorial's Chapter 16.
=end

    attr_reader :inst, :trans
    
    def initialize( inst )
        @inst = inst
        @trans = inst.transformation.to_a()
    end # of initialize
    
    def move( *args ) # Point3d or Vector3d or [r,g,b]
        if args.length == 3
            move_tw( args[0], args[1], args[2] )
        elsif args[0].is_a?( Array )
            move_tw( args[0][0], args[0][1], args[0][2] )
        elsif args[0].is_a?( Geom::Vector3d )
            move_tw( args[0].x, args[0].y, args[0].z )
        elsif args[0].is_a?( Geom::Point3d )
            move_to( args[0].x, args[0].y, args[0].z )
        else
            raise "move cannot handle " + args[0].to_s()
        end
    end # of move()
    
    def move_to( r, g, b ) # move to given point
        @trans[12] = r; @trans[13] = g; @trans[14] = b
        @inst.move!( @trans )
    end # of move_to()
    
    def move_tw( r, g, b ) # move toward, per vector
        @trans[12] += r; @trans[13] += g; @trans[14] += b
        @inst.move!( @trans )
    end # of move_tw()
    
    def rotate( point, plane_or_axis, degrees )
    
        axis = make_axis(plane_or_axis)
        degrees *= $radians_per_degree
        inst_xform = Matrix.new( 4, 4, @inst.transformation.to_a() )
        xform = Geom::Transformation.rotation( point, axis, degrees )
        xform = Matrix.new( 4, 4, xform.to_a() )
        @inst.move!( (inst_xform * xform).values )
    
    end # of rotate()
    
    def scale( *args )
        case args.length
            when 1 then scale_g( args[0] )
            when 2 then scale_pg( args[0], args[1] )
            when 3 then scale_rgb( args[0], args[1], args[2] )
            when 4 then scale_prgb( args[0], args[1], args[2], args[3] )
        end
    end # of scale()
    
    def scale_g( scale_factor )
        trans = inst.transformation().to_a()
        trans[15] /= scale_factor
        t = Geom::Transformation.new( trans )
        @inst.move!( t )
    end # of scale_g()
    
    def scale_pg( point, scale_factor )
        point = point.to_a() if 
            point.is_a?( Geom::Point3d )
        trans = inst.transformation().to_a()
        trans[15] /= scale_factor
        trans[12] = adjust_tv( trans[12], point[0], scale_factor )
        trans[13] = adjust_tv( trans[13], point[1], scale_factor )
        trans[14] = adjust_tv( trans[14], point[2], scale_factor )
        inst.move!( Geom::Transformation.new(trans) )
        
    end # of scale_pg()
    
    def scale_rgb( scale_r, scale_g, scale_b )
        
        inst_xform = Matrix.new( 4, 4, inst.transformation().to_a() )
        scale_xform = Matrix.new( 4, 4, 
            [scale_r,0,0,0, 
             0,scale_g,0,0,
             0,0,scale_b,0,
             0,0,0,1] )

        @inst.move!( (inst_xform*scale_xform).values ) # not commutative!

    end # of scale_rgb()
    
    def scale_prgb( point, scale_r, scale_g, scale_b )
        point = point.to_a() if 
            point.is_a?( Geom::Point3d )
        
        inst_xform = Matrix.new( 4, 4, inst.transformation().to_a() )
        
        t1 = Geom::Transformation.scaling( point, scale_r, scale_g, scale_b )
        scale_xform = Matrix.new( 4, 4, t1.to_a() )

        @inst.move!( (inst_xform*scale_xform).values ) # not commutative!

    end # of scale_prgb()
    
# support methods     
    
    def adjust_tv( was, pt, scale ) # adjust translate vector for scaling
        new_dist = ( was - pt ) * scale
        new_loc = pt + new_dist
        return new_loc / scale
    end # of adjust_tv()

    def make_axis( plane_or_axis ) # for rotating

        if plane_or_axis.is_a?( String )
            case plane_or_axis
                when 'rg' then axis = [0,0,1]
                when 'rb' then axis = [0,1,0]
                when 'gb' then axis = [1,0,0]
                else
                    raise "Plane must be 'rg', 'rb', 'gb' or an axis."
            end
        else
            axis = plane_or_axis
        end
    
        return axis

    end # of make_axis()

    def inspect()
        return '#<Movable' + @inst.to_s() + '>'
    end # of inspect()
    
end # of class MovableCI

class Matrix
=begin
You can multiply one matrix by another with this class.

In m1 * m2, the number of rows in m1 must equal the number of columns in 
m2. This code does absolutely no checking. Program must check sizes before 
calling this code! (Application herein: square matrices of equal size, 
where this is not an issue.) 
=end
    
    attr_reader :nrows, :ncols, :values
    
    def initialize( nrows, ncols, values )
        @nrows = nrows
        @ncols = ncols
        @values = values
    end # of initialize()
    
    def * ( m2 )
        vals = []
        for r in 0..(@nrows-1)
            for c in 0..(m2.ncols-1)
                vals.push( row_col(row( r ), m2.col( c )) )
            end
        end
        return Matrix.new( @nrows, m2.ncols, vals )
    end # of *()

    def [] ( row, col )
        return @values[ row * @ncols + col ]
    end # of []()
    
    def col( c )
        ret = []
        for r in 0..(@nrows-1)
            ret.push( @values[r*@ncols + c] )
        end
        return ret
    end # of col()

    def row( r )
        start = r * @ncols
        return @values[ start .. (start + @ncols - 1) ]
    end # of row()
    
    def row_col( row, col )
        ret = 0
        for i in 0..(row.length()-1)
            ret += row[ i ] * col[ i ]
        end
        return ret
    end
    
    def inspect()
        ret = ''
        for r in 0..(@nrows-1)
            for c in 0..(@ncols-1)
                ret += self[r, c].to_s
                ret += ', ' if c < (@ncols-1)
            end
            ret += "\n"
        end
        return ret
    end # of inspect()
    
end # of class Matrix

# end of movable_ci.rb