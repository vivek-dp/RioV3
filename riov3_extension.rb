require 'sketchup.rb'
require 'extensions.rb'

new_version = '2.1.0'

rio_extension   = Sketchup.extensions['RioSTD']
RIO_ROOT_PATH     = "C:/RioSTD/"
RIO_ROOT_PATH     = "E:/working/"

if !rio_extension || (rio_extension.version != new_version)
    rio_extension             = SketchupExtension.new("RioSTD", RIO_ROOT_PATH+'loader.rb')
    rio_extension.name        = 'RioSTD'
    rio_extension.version     = new_version
    rio_extension.description = "RioSTD"
    rio_extension.copyright   = "2019"
    rio_extension.creator     = "Decorpot"
    Sketchup.rio_extension(rio_extension, true)
end