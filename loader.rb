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

def print_attributes
	seln = Sketchup.active_model.selection[0]
	if seln
		get_attributes seln
	else
		puts "Nothing selected"
	end
end

tools_file = File.join(RIO_ROOT_PATH, 'tools/load_tools')
 
unless file_loaded?(__FILE__)
	menu = UI.menu('Plugins')
	menu.add_item('RIO Attribute Inspector') {
		print_attributes
	}
	file_loaded(__FILE__)
end






def load_settings 
    json_hash = {
        "ANALYSIS": 'analysis_settings.json', 
    }
    settings_hash = {}
    json_hash.each do |key, file_name|
        full_path   = File.join(RIO_SETTINGS_PATH, file_name)
        json_file 	= File.open(full_path, 'r')
        data		= JSON.load json_file
        settings_hash[key] = data
    end
    
    $RIO_SET = settings_hash
end

def load_layers
    ['RIO_Component', 'RIO_Wall', 'RIO_Door', 'RIO_Window', 'RIO_Column', 'RIO_Beam'].each {|layer_name|
        layer = Sketchup.active_model.layers[layer_name]
        Sketchup.active_model.layers.add(layer_name) unless layer
        layer.name=layer_name if layer
    }
end

def preload_items
    load_settings
    load_layers
end

preload_items

DEVELOPER_MODE = true

if DEVELOPER_MODE
    #Debug levels ....Change to single function and debug levels
    def RIODEBUG message
        puts message
    end

    def RIOLOG message
        puts message
    end

    def RIOWARN message
        puts message
    end
	
	def RIOALERT message
		UI.messagebox(message, MB_OKCANCEL)
	end
    #---------------------------------------------------------------
    SKETCHUP_CONSOLE.show
else
    def RIODEBUG message;end
    def RIOLOG message;end
    def RIOWARN message;end
	def RIOALERT message;end
end

def operation_dialog
    html_str = 
        '
        <!DOCTYPE html>
        <html>
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/semantic-ui/2.4.1/semantic.min.css">'
end

def load_constants
    unless defined?(PERP_POLYGON)
        #RoomFloor types
        # TRIANGLE                    = 1
        # RECTANGLE                   = 2
        # PERP_POLYGON                = 3

        #Irregular
        # QUADRILATERAL               = 4
        # SINGLE_SLOPE_POLYGON        = 5
        # MULTI_SLOPE_POLYGON         = 6
    end
end

def r3
	load 'E:\V3\Working\features\CivilFeatures.rb'
	load 'E:/V3/Working/core/SketchupHelper.rb'
	load 'E:/V3/Working/core/CivilHelper.rb'
	load 'E:/V3/Working/testing/wall_helper.rb'
end

def a3
	seln = Sketchup.active_model.selection[0]
	if seln
		get_attributes seln
	else
		puts "Nothing selected"
	end
end