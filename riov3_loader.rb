require "json"

RIO_ROOT_PATH   = File.join(File.dirname(__FILE__)) unless defined? RIO_ROOT_PATH
RIO_SETTINGS_PATH   = File.join(RIO_ROOT_PATH, '/' , 'settings/') unless defined? RIO_SETTINGS_PATH

def rioload_ruby path
    ruby_file_name = path + '.rb'
    file_name = File.join(RIO_ROOT_PATH, ruby_file_name)
    puts file_name
    if File.exists?(file_name)
        return Sketchup.load file_name
    end
end

tools_file = File.join(RIO_ROOT_PATH, 'tools/load_tools')
require tools_file


def dload
    ruby_files = Dir.glob(RIO_ROOT_PATH+'features/*.rb')
    ruby_files.each { |file_name|
        load file_name
		puts "Loading #{file_name}"
    }
	ruby_files = Dir.glob(RIO_ROOT_PATH+'core/*.rb')
    ruby_files.each { |file_name|
        load file_name
		puts "Loading #{file_name}"
    }
end

def uload 
	ruby_files = Dir.glob(RIO_ROOT_PATH+'tools/*.rb')
    ruby_files.each { |file_name|
        load file_name
		puts "Loading #{file_name}"
    }
end

def a3
	seln = Sketchup.active_model.selection[0]
	if seln
		get_attributes seln
	else
		puts "Nothing selected"
	end
end

def set_global_rio_dictionary
	model_dictionaries = Sketchup.active_model.attribute_dictionaries
	rio_attribute_dictionary = model_dictionaries['rio_model_atts']
	unless rio_attribute_dictionary
		model_dictionaries.add
	end
end

def load_layers
    ['RIO_Component', 'RIO_Wall', 'RIO_Door', 'RIO_Window', 'RIO_Column', 'RIO_Beam'].each {|layer_name|
        layer = Sketchup.active_model.layers[layer_name]
        Sketchup.active_model.layers.add(layer_name) unless layer
        layer.name=layer_name if layer
    }
	['RIO_Component', 'RIO_Civil_Wall', 'RIO_Civil_Door', 'RIO_Civil_Window', 'RIO_Civil_Column', 'RIO_Civil_Beam'].each {|layer_name|
        layer = Sketchup.active_model.layers[layer_name]
        Sketchup.active_model.layers.add(layer_name) unless layer
        layer.name=layer_name if layer
    }
end

load_layers
RIO::DevTools::load_menu_items
RIO::DevTools::load_utilities
RIO::DevTools::room_details



