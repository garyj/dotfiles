import Gio from 'gi://Gio';
import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';

const IFACE = `
<node>
  <interface name="org.garyj.WindowTools">
    <method name="MoveToWorkspace">
      <arg type="i" direction="in" name="workspace_index"/>
    </method>
    <method name="ActivateByTitle">
      <arg type="s" direction="in" name="search"/>
      <arg type="s" direction="out" name="result"/>
    </method>
  </interface>
</node>`;

export default class WindowToolsExtension extends Extension {
    _dbus = null;
    _ownerId = 0;

    enable() {
        this._dbus = Gio.DBusExportedObject.wrapJSObject(IFACE, this);
        this._dbus.export(Gio.DBus.session, '/org/garyj/WindowTools');
        this._ownerId = Gio.bus_own_name(
            Gio.BusType.SESSION,
            'org.garyj.WindowTools',
            Gio.BusNameOwnerFlags.NONE,
            null, null, null
        );
    }

    disable() {
        if (this._dbus) {
            this._dbus.unexport();
            this._dbus = null;
        }
        if (this._ownerId) {
            Gio.bus_unown_name(this._ownerId);
            this._ownerId = 0;
        }
    }

    MoveToWorkspace(workspaceIndex) {
        const w = global.display.focus_window;
        if (!w) return;
        const ws = global.workspace_manager.get_workspace_by_index(workspaceIndex);
        if (ws) w.change_workspace(ws);
    }

    ActivateByTitle(search) {
        const dominated = search.toLowerCase();
        const windows = global.get_window_actors()
            .map(a => a.meta_window)
            .filter(w => w.get_title() && w.get_title().toLowerCase().includes(dominated));

        if (windows.length === 0) return 'not_found';

        const win = windows[0];
        win.change_workspace(global.workspace_manager.get_active_workspace());
        win.activate(global.get_current_time());
        return 'found:' + windows.length;
    }
}
