/* Copyright 2014-2019 Go For It! developers
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

/**
 * A class that handles access to settings in a transparent manner.
 * Its main motivation is the option of easily replacing Glib.KeyFile with
 * another settings storage mechanism in the future.
 */
private class GOFI.SettingsManager {
    private KeyFile key_file;

    /*
     * A list of constants that define settings group names
     */
    private const string GROUP_TODO_TXT = "Todo.txt";
    private const string GROUP_TIMER = "Timer";
    private const string GROUP_UI = "Interface";
    private const string GROUP_LISTS = "Lists";

    private const int DEFAULT_TASK_DURATION = 1500;
    private const int DEFAULT_BREAK_DURATION = 300;
    private const int DEFAULT_REMINDER_TIME = 60;

    // Whether or not Go For It! has been started for the first time
    public bool first_start = false;

    /*
     * A list of settings values with their corresponding access methods.
     * The "heart" of the SettingsManager class.
     */

    /*---GROUP:Todo.txt------------------------------------------------------*/
    public string todo_txt_location {
        owned get { return get_value (GROUP_TODO_TXT, "location"); }
    }
    /*---GROUP:Timer---------------------------------------------------------*/
    public int task_duration {
        get {
            var default_str = DEFAULT_TASK_DURATION.to_string ();
            var duration = get_value (GROUP_TIMER, "task_duration", default_str);
            var parsed_duration = int.parse (duration);
            if (parsed_duration <= 0) {
                warning ("Invalid task duration: %s", duration);
                return DEFAULT_TASK_DURATION;
            }
            return parsed_duration;
        }
        set {
            set_value (GROUP_TIMER, "task_duration", value.to_string ());
            timer_duration_changed ();
        }
     }
    public int break_duration {
        get {
            var default_str = DEFAULT_BREAK_DURATION.to_string ();
            var duration = get_value (GROUP_TIMER, "break_duration", default_str);
            var parsed_duration = int.parse (duration);
            if (parsed_duration <= 0) {
                warning ("Invalid break duration: %s", duration);
                return DEFAULT_BREAK_DURATION;
            }
            return parsed_duration;
        }
        set {
            set_value (GROUP_TIMER, "break_duration", value.to_string ());
            timer_duration_changed ();
        }
    }
    public int reminder_time {
        get {
            var default_str = DEFAULT_REMINDER_TIME.to_string ();
            var time = get_value (GROUP_TIMER, "reminder_time", default_str);
            var parsed_time = int.parse (time);
            if (parsed_time < 0) {
                warning ("Invalid reminder time: %s", time);
                return 0;
            }
            return parsed_time;
        }
        set {
            set_value (GROUP_TIMER, "reminder_time", value.to_string ());
        }
    }
    public bool reminder_active {
        get {
            return (reminder_time > 0);
        }
    }
    /*---GROUP:UI-------------------------------------------------------------*/
    public int win_x {
        get {
            var x = get_value (GROUP_UI, "win_x", "-1");
            return int.parse (x);
        }
        set {
            set_value (GROUP_UI, "win_x", value.to_string ());
        }
    }
    public int win_y {
        get {
            var y = get_value (GROUP_UI, "win_y", "-1");
            return int.parse (y);
        }
        set {
            set_value (GROUP_UI, "win_y", value.to_string ());
        }
    }
    public int win_width {
        get {
            var width = get_value (GROUP_UI, "win_width", "350");
            return int.parse (width);
        }
        set {
            set_value (GROUP_UI, "win_width", value.to_string ());
        }
    }
    public int win_height {
        get {
            var height = get_value (GROUP_UI, "win_height", "650");
            return int.parse (height);
        }
        set {
            set_value (GROUP_UI, "win_height", value.to_string ());
        }
    }
    public bool use_header_bar {
        get {
            var use_header_bar = get_value (
                GROUP_UI, "use_header_bar", header_bar_default ()
            );
            return bool.parse (use_header_bar);
        }
        set {
            set_value (GROUP_UI, "use_header_bar", value.to_string ());
            use_header_bar_changed ();
        }
    }
    public bool use_dark_theme {
        get {
            var use_dark = get_value (
                GROUP_UI, "use_dark_theme", "false"
            );
            return bool.parse (use_dark);
        }
        set {
            set_value (GROUP_UI, "use_dark_theme", value.to_string ());
            use_dark_theme_changed (value);
        }
    }
    public Theme theme {
        get {
            var theme_str = get_value (
                GROUP_UI, "theme", "elementary"
            );
            var theme_val = Theme.from_string (theme_str);

            if (theme_val != Theme.INVALID) {
                return theme_val;
            }
            warning ("Unknown theme setting: %s", theme_str);
            return Theme.ELEMENTARY;
        }
        set {
            set_value (GROUP_UI, "theme", value.to_string ());
            theme_changed (value);
        }
    }
    public Gtk.IconSize toolbar_icon_size {
        owned get {
            var icon_size = get_value (
                GROUP_UI, "icon_size", "large"
            );
            switch (icon_size) {
                case "small":
                    return Gtk.IconSize.SMALL_TOOLBAR;
                case "large":
                    return Gtk.IconSize.LARGE_TOOLBAR;
                default:
                    warning ("Unknown toolbar icon size");
                    return Gtk.IconSize.LARGE_TOOLBAR;
            }
        }
        set {
            string size_str;
            if (value == Gtk.IconSize.SMALL_TOOLBAR) {
                size_str = "small";
            } else {
                size_str = "large";
            }
            set_value (GROUP_UI, "icon_size", size_str);
            toolbar_icon_size_changed (value);
        }
    }
    public bool switcher_use_icons {
        get {
            var label_type = get_value (
                GROUP_UI, "switcher_label_type", "icons"
            );
            switch (label_type) {
                case "icons":
                    return true;
                case "text":
                    return false;
                default:
                    warning ("Unknown switcher setting: %s, expected icons/text", label_type);
                    return true;
            }
        }
        set {
            set_value (GROUP_UI, "switcher_label_type", value ? "icons" : "text");
            switcher_use_icons_changed (value);
        }
    }
    /*---GROUP:LISTS----------------------------------------------------------*/
    public List<ListIdentifier?> lists {
        owned get {
            List<ListIdentifier?> identifiers = new List<ListIdentifier?> ();
            var strs = get_string_list (GROUP_LISTS, "lists", {});

            foreach (string id_str in strs) {
                var identifier = ListIdentifier.from_string (id_str);
                if (identifier != null) {
                    identifiers.prepend ((owned) identifier);
                } else {
                    warning ("Can't decode list information! (%s)", id_str);
                }
            }
            return identifiers;
        }
        set {
            string[] _lists = {};
            foreach (unowned ListIdentifier identifier in value) {
                _lists += identifier.to_string ();
            }

            set_string_list (GROUP_LISTS, "lists", _lists);
        }
    }
    public ListIdentifier? list_last_loaded {
        owned get {
            var encoded_id = get_value (GROUP_LISTS, "last", "");
            if (encoded_id != "") {
                return ListIdentifier.from_string (encoded_id);
            }
            return null;
        }
        set {
            if (value == null) {
                set_value (GROUP_LISTS, "last", "");
            } else {
                set_value (GROUP_LISTS, "last", value.to_string ());
            }
        }
    }

    /* Signals */
    public signal void todo_txt_location_changed ();
    public signal void timer_duration_changed ();
    public signal void theme_changed (Theme theme);
    public signal void use_dark_theme_changed (bool use_dark);
    public signal void use_header_bar_changed ();
    public signal void toolbar_icon_size_changed (Gtk.IconSize size);
    public signal void switcher_use_icons_changed (bool use_icons);

    /**
     * Constructs a SettingsManager object from a configuration file.
     * Reads the corresponding file and creates it, if necessary.
     */
    public SettingsManager.load_from_key_file () {
        // Instantiate the key_file object
        key_file = new KeyFile ();

        if (!FileUtils.test (GOFI.Utils.config_file, FileTest.EXISTS)) {
            int dir_exists = DirUtils.create_with_parents (
                GOFI.Utils.config_dir, 0775
            );
            if (dir_exists != 0) {
                error (_("Couldn't create directory: %s"), GOFI.Utils.config_dir);
            }
            if (!import_from_old_path ()) {
                stdout.printf ("old file not imported\n");
                first_start = true;
            }
        } else {
            // If it does exist, read existing values
            try {
                key_file.load_from_file (GOFI.Utils.config_file,
                   KeyFileFlags.KEEP_COMMENTS | KeyFileFlags.KEEP_TRANSLATIONS);
            } catch (Error e) {
                stderr.printf ("Reading %s failed", GOFI.Utils.config_file);
                error ("%s", e.message);
            }
        }
    }

    private string header_bar_default () {
        if (GOFI.Utils.desktop_hb_status.use_feature (true)) {
            return "true";
        }
        return "false";
    }

    /**
     * Provides read access to a setting, given a certain group and key.
     * Public access is granted via the SettingsManager's attributes, so this
     * function has been declared private
     */
    private string get_value (string group, string key, string default = "") {
        try {
            // use key_file, if it has been assigned
            if (key_file != null
                && key_file.has_group (group)
                && key_file.has_key (group, key)) {
                    return key_file.get_value (group, key);
            } else {
                return default;
            }
        } catch (Error e) {
                error ("An error occured while reading the setting"
                    +" %s.%s: %s", group, key, e.message);
        }
    }

    /**
     * Provides write access to a setting, given a certain group key and value.
     * Public access is granted via the SettingsManager's attributes, so this
     * function has been declared private
     */
    private void set_value (string group, string key, string value) {
        if (key_file != null) {
            try {
                key_file.set_value (group, key, value);
                write_key_file ();
            } catch (Error e) {
                error ("An error occured while writing the setting"
                    +" %s.%s to %s: %s", group, key, value, e.message);
            }
        }
    }

    private string[] get_string_list (string group, string key, string[] default = {}) {
        try {
            // use key_file, if it has been assigned
            if (key_file != null
                && key_file.has_group (group)
                && key_file.has_key (group, key)) {
                    return key_file.get_string_list (group, key);
            } else {
                return default;
            }
        } catch (Error e) {
                error ("An error occured while reading the setting"
                    +" %s.%s: %s", group, key, e.message);
        }
    }

    private void set_string_list (string group, string key, string[] string_list) {
        if (key_file != null) {
            try {
                key_file.set_string_list (group, key, string_list);
                write_key_file ();
            } catch (Error e) {
                error (
                    "An error occured while writing the setting" +
                    " %s.%s to {%s}: %s",
                     group, key, string.joinv (", ", string_list), e.message
                );
            }
        }
    }

    /**
     * Function made for compability with older versions of GLib.
     */
    private void write_key_file () throws Error {
        GLib.FileUtils.set_contents (GOFI.Utils.config_file, key_file.to_data ());
    }

    /**
     * Try to read the configuration from a keyfile from an older version.
     */
    private bool import_from_old_path () {
        if (!FileUtils.test (GOFI.Utils.old_config_file, FileTest.EXISTS)) {
            return false;
        }

        // Instantiate the key_file object
        var old_file = new KeyFile ();

        try {
            old_file.load_from_file (GOFI.Utils.old_config_file,
               KeyFileFlags.KEEP_COMMENTS | KeyFileFlags.KEEP_TRANSLATIONS);
        } catch (Error e) {
            stderr.printf ("Reading %s failed", GOFI.Utils.old_config_file);
            warning ("%s", e.message);
            return false;
        }

        try {
            import_group (
                old_file, GROUP_TODO_TXT,
                {"location"}
            );
            import_group (
                old_file, GROUP_TIMER,
                {"task_duration", "break_duration", "reminder_time"}
            );
            import_group (
                old_file, GROUP_UI,
                {"win_x", "win_y", "win_width", "win_height", "use_dark_theme"}
            );
       } catch (KeyFileError e) {
            warning (
                _("Couldn't properly import settings from %s: %s"),
                GOFI.Utils.old_config_file, e.message
            );
            return false;
        }
        return true;
    }

    private void import_group (KeyFile old_file, string group, string[] keys) throws KeyFileError {
        if (!old_file.has_group (group)) {
            return;
        }
        foreach (string key in keys) {
            if (old_file.has_key (group, key)) {
                key_file.set_value (group, key, old_file.get_value (group, key));
            }
        }
    }
}
