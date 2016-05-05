/* Copyright 2016 Go For It! developers
*
* This file is part of Go For It!.
*
* Go For It! is free software: you can redistribute it
* and/or modify it under the terms of version 3 of the 
* GNU General Public License as published by the Free Software Foundation.
*
* Go For It! is distributed in the hope that it will be
* useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
* Public License for more details.
*
* You should have received a copy of the GNU General Public License along
* with Go For It!. If not, see http://www.gnu.org/licenses/.
*/

using GOFI;

namespace GOFI.Plugins.TodoTXT {
    
    private bool types_initialized = false;
    
    /**
     * This function creates instances of objects to register their types.
     * It is needed because otherwise 
     */
    private void init_types () {
        if (!types_initialized) {
            new TXTTask ();
        }
    }
    
    private SettingsManager _settings;
    
    /**
     * ...
     */
    public class TXTPluginProvider : GOFI.TodoPluginProvider {
        private SettingsManager settings {
            get {
                if (_settings == null) {
                    _settings = new SettingsManager.load_from_key_file ();
                }
                return _settings;
            }
            set {
                _settings = value;
            }
        }

        public override void on_activate () {
            init_types ();
        }
        
        public override void on_deactivate () {
            
        }
        
        public override TodoPlugin get_plugin (TaskTimer timer) {
            return new TXTPlugin (timer, settings);
        }
    }
    
    /**
     * ...
     */
    public class TXTPlugin : TodoPlugin {
        
        private SettingsManager settings;
        private TaskManager task_manager;
        
        // Primary and secondary widgets
        private TodoView todo_list_view;
        private TodoView done_list_view;
        
        // Menu items for this plugin
        private Gtk.MenuItem clear_done_item;
        
        public TXTPlugin (TaskTimer timer, SettingsManager settings) {
            base (timer);
            
            this.settings = settings;
            task_manager = new TaskManager (settings);
            
            setup_widgets ();
            setup_menu ();
            connect_signals ();
        }
        
        ~TXTPlugin () {
            todo_list_view.destroy ();
            done_list_view.destroy ();
        }
        
        private void setup_widgets () {
            todo_list_view = new TodoView (true);
            done_list_view = new TodoView ();
            
            bind_models ();
        }
        
        private void setup_menu () {
            /* Initialization */
            clear_done_item = new Gtk.MenuItem.with_label (_("Clear Done List"));
            
            /* Add Items to Menu */
            menu_items.add (clear_done_item);
        }
        
        private void set_active_task (TXTTask? task) {
            task_timer.active_task = task;
            task_manager.active_task = task;
        }
        
        private void connect_signals () {
            todo_list_view.task_selected.connect (set_active_task);
            todo_list_view.add_new_task.connect (task_manager.add_task_from_txt);
            
            task_manager.active_task_completed.connect (() => {
                TXTTask task;
                
                if (task_timer.running || 
                    task_timer.active_task == task_manager.active_task)
                {
                    task_timer.remove_task ();
                    task = todo_list_view.get_selected ();
                    set_active_task(task);
                }
            });
            task_manager.active_task_invalid.connect (() => {
                TXTTask task;
                task_timer.remove_task ();
                task = todo_list_view.get_selected ();
                set_active_task(task);
            });
            clear_done_item.activate.connect ( () => {
                task_manager.clear_done_store ();
            });
        }
        
        private void bind_models () {
            todo_list_view.set_store (task_manager.todo_store);
            done_list_view.set_store (task_manager.done_store);
        }
        
        public override void stop () {
            if (task_timer.active_task != null) {
                task_timer.remove_task ();
            }
        }
        
        public override Gtk.Widget get_primary_widget (out string page_name) {
            page_name = _("To-Do");
            return todo_list_view;
        }
        
        public override Gtk.Widget get_secondary_widget (out string page_name) {
            page_name = _("Done");
            return done_list_view;
        }
    }
}
    
[ModuleInit]
public void peas_register_types (GLib.TypeModule module)
{
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type (typeof (Peas.Activatable),
                                       typeof (GOFI.Plugins.TodoTXT.TXTPluginProvider));
}