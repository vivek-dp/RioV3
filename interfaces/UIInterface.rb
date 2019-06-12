#-------------------------------------------------------------------------------------
# This file will contain all the User Interface code.
# Write all thos functions here
#
#
# Comment by : Vivek.G June-8-2019
#-------------------------------------------------------------------------------------

module RIO
    module RioUI
        class RioUIInterface
            @@rio_dialog = nil
            def initialize
                @rio_load_url   = "http://localhost/3000"
                @dialog_width   = 800
                @dialog_height  = 600
            end

            def get_dialog_settings

            end
        end #class RioUIInterface
    end #module RioUI
end #module RIO

#-------------------------------------------------------------------------------------