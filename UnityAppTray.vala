using Gtk, Gee;

public class Main {

  class UnityAppTray {

    private HashMap<ulong, StatusIcon> theMap = new HashMap<ulong, StatusIcon>();

    public UnityAppTray() {
    }

    public void init() {

        Wnck.Screen screen = Wnck.Screen.get_default();
        screen.force_update();

        // ON OPEN
        screen.window_opened.connect( window_opened );

        // ON CLOSE
        screen.window_closed.connect( (aWindow) => {
         stdout.printf("closed [window='%s']\n", aWindow.get_name());

         if(aWindow.has_name()) {
             StatusIcon icon = theMap.get(aWindow.get_xid());
             if(icon!=null) {
                 icon.set_visible(false);
                 //unowned icon;
                 theMap.unset(aWindow.get_xid());
             }
         }
        });

        // SHOW ALL WINDOWS ON TRAY
        weak GLib.List<Wnck.Window> list = screen.get_windows();
        foreach(Wnck.Window win in list) {
            if(win.get_class_group().get_name()!="" && win.get_name()!="x-nautilus-desktop") {
                window_opened(win);
            }
        }

    }

    // on open window
    public void window_opened(Wnck.Window aWindow) {
        stdout.printf("opened [window='%s', xid=%x, group='%s']\n", aWindow.get_name(), (uint)aWindow.get_xid(), aWindow.get_class_group().get_name());

        // FILTER
        if(aWindow.get_name() == "<unknown>") return ;
        if(aWindow.get_name() == "e.sinev - Skype™ (Beta)") return;

        // CREATE ICON ON TRAY 
        StatusIcon trayicon = new StatusIcon.from_pixbuf(aWindow.get_icon()) ; //new StatusIcon();
        trayicon.set_tooltip_text (aWindow.get_name());
        trayicon.set_visible(true);
        theMap.set(aWindow.get_xid(), trayicon);

        // ON ICON CLICKED
        trayicon.activate.connect( () => {

            if( aWindow.is_active() && aWindow.is_visible_on_workspace( aWindow.get_workspace() )) {
                aWindow.minimize();
            } else {
                aWindow.unminimize(Gtk.get_current_event_time());
            }
            // (item.user_data as Wnck.Window).make_above();
            // (item.user_data as Wnck.Window).unmake_above();
        });  

        // ON TITLE CHANGED
        aWindow.name_changed.connect( () => { trayicon.set_tooltip_text ( aWindow.get_name()); } );
        aWindow.icon_changed.connect( () => { trayicon.set_from_pixbuf  ( aWindow.get_icon()); } );

    }
  }

  public static int main (string[] args) {
    Gtk.init(ref args);

    var app = new UnityAppTray();
    app.init();

    Gtk.main();
    return 0;
  }
}
