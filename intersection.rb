mod = Sketchup.active_model
ent = mod.entities
grp = ent.grep(Sketchup::Group)

intersections = []

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
   sz2 = new_grp.entities.grep(Sketchup::Face).length
   puts "Geometry Overlaps in #{a} and #{b}" if  sz1!= sz2
   #mod.abort_operation()
 end
}