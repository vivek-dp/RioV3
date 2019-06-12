module OpTool
    def self.box_dialog
        html_file =  File.join(__dir__, 'operation_tool.html')
        options = {
          :dialog_title => 'OpTool',
          :style => UI::HtmlDialog::STYLE_DIALOG
        }
        dialog = UI::HtmlDialog.new(options)
        puts "html file : #{html_file}"
        dialog.set_file(html_file)
        dialog.center
        dialog
    end
      
    def self.show_dialog
        dialog ||= box_dialog
        if dialog.visible?
            dialog.bring_to_front
        else
            dialog.show
        end 
        dialog.add_action_callback("startOperation"){|action_context|
            puts "Sketchup starts operation"
            Sketchup.active_model.start_operation("Rio Test Operation", true)
        }
        dialog.add_action_callback("abortOperation"){|action_context|
            puts "Sketchup abort operation"
            Sketchup.active_model.abort_operation
        }
    end
end