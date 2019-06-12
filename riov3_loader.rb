require "json"

RIO_ROOT_PATH   = File.join(File.dirname(__FILE__))
RIO_SETTINGS_PATH   = File.join(RIO_ROOT_PATH, '/' , 'settings/')

def rioload_ruby path
    ruby_file_name = path + '.rb'
    file_name = File.join(RIO_ROOT_PATH, ruby_file_name)
    puts file_name
    if File.exists?(file_name)
        return Sketchup.load file_name
    end
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
    ['RIO_Component', 'RIO_Wall', 'RIO_Door', 'RIO_Window'].each {|layer_name|
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
    #---------------------------------------------------------------
    SKETCHUP_CONSOLE.show
else
    def RIODEBUG message;end
    def RIOLOG message;end
    def RIOWARN message;end
end

def operation_dialog
    html_str = 
        '
        <!DOCTYPE html>
        <html>
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/semantic-ui/2.4.1/semantic.min.css">'
end