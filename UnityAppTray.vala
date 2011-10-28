using Gtk, Gee;

//public class Main {

  class UnityAppTray {

    private HashMap<ulong, StatusIcon> theMap = new HashMap<ulong, StatusIcon>();
    private StatusIcon theShowDesktopIcon;

    public UnityAppTray() {
    }


    private void setOrigIcon(Wnck.Window aWindow) {
        StatusIcon icon = theMap.get(aWindow.get_xid());
        if(icon!=null) {
            icon.set_from_pixbuf(aWindow.get_icon());
        }
    }    

    private void setSaturatedIcon(Wnck.Window aWindow) {
        StatusIcon icon = theMap.get(aWindow.get_xid());
        if(icon!=null) {
                var pixbuf2 = icon.get_pixbuf().copy();
                icon.get_pixbuf().saturate_and_pixelate(pixbuf2, 0.0f, true);
                icon.set_from_pixbuf(pixbuf2);
        }
    }    
    
    public void init() {

        Wnck.Screen screen = Wnck.Screen.get_default();
        screen.force_update();

        screen.active_window_changed.connect( (aPreviousWindow) => {
            
            Wnck.Window activeWindow = screen.get_active_window();
            if(activeWindow!=null)    setOrigIcon(activeWindow);
            if(aPreviousWindow!=null) setSaturatedIcon(aPreviousWindow);
            
        });
        
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

        addShowDesktopIcon();

        
        // SHOW ALL WINDOWS ON TRAY
        weak GLib.List<Wnck.Window> list = screen.get_windows();
        foreach(Wnck.Window win in list) {
            if(win.get_class_group().get_name()!="" && win.get_name()!="x-nautilus-desktop") {
                Gdk.threads_enter();
                    window_opened(win);
                    //Thread.usleep (1000000);
                Gdk.threads_leave();
            }
        }
            
    }

    private bool areNotAllWindowsMinimized() {
        Wnck.Screen screen = Wnck.Screen.get_default();
        screen.force_update();
        weak GLib.List<Wnck.Window> list = screen.get_windows();
        foreach(Wnck.Window win in list) {
            if(isAllowed(win) && !win.is_minimized()) {
                stdout.printf(@"    window '%s' is not minimized\n", win.get_name());
                return true;
            }
        }
        return false;
    }
    
    private void addShowDesktopIcon() {
        theShowDesktopIcon = new StatusIcon.from_stock("gtk-strikethrough") ; // Stock.STRIKETHROUGH) ; for ubuntu 10.10
        theShowDesktopIcon.set_tooltip_text ("Show Desktop");
        theShowDesktopIcon.set_visible(true);

        
        theShowDesktopIcon.activate.connect( () => {
            if(areNotAllWindowsMinimized()) {
                Wnck.Screen screen = Wnck.Screen.get_default();
                screen.force_update();
                weak GLib.List<Wnck.Window> list = screen.get_windows();
                foreach(Wnck.Window win in list) {
                    if(isAllowed(win) && !win.is_minimized()) {
                        win.minimize();
                    }
                }
            }
        });  
        
    }
    
    private bool isAllowed(Wnck.Window aWindow) {
        // FILTER
        if(aWindow.get_name() == "panel") return false;
        if(aWindow.get_name() == "launcher") return false;
        if(aWindow.get_name() == "compiz") return false;
        if(aWindow.get_name() == "Desktop") return  false;
        if(aWindow.get_name() == "x-nautilus-desktop") return  false;
        if(aWindow.get_name() == "<unknown>") return  false;
        if(aWindow.get_name() == "") return  false;
        if(aWindow.get_name() == "Untitled window") return  false;

        try {
            if(new GLib.Regex(".* - Skype™ \\(Beta\\).*").match(aWindow.get_name())) return false;        
        } catch (GLib.RegexError e) {
            return true;
        }    

        if(aWindow.get_class_group().get_name() == "Gnome-panel") return false;
        
        return true;
    }
    
    private void nextImage(StatusIcon aTrayIcon) {
         aTrayIcon.set_from_pixbuf(
            aTrayIcon.get_pixbuf().rotate_simple(Gdk.PixbufRotation.CLOCKWISE)
         );
    }
    
    // on open window
    public void window_opened(Wnck.Window aWindow) {
        stdout.printf("opened [window='%s', xid=%x, group='%s']\n", aWindow.get_name(), (uint)aWindow.get_xid(), aWindow.get_class_group().get_name());

        // FILTER
        if(! isAllowed(aWindow)) {
            return ;
        }

        // CREATE ICON ON TRAY 
        StatusIcon trayicon = new StatusIcon.from_pixbuf(aWindow.get_icon()) ; //new StatusIcon();
        trayicon.set_tooltip_text (aWindow.get_name());
        trayicon.set_visible(true);
        
        trayicon.scroll_event.connect( () => { 
            nextImage(trayicon);
            return true;
        } );
        
        theMap.set(aWindow.get_xid(), trayicon);
        setSaturatedIcon(aWindow);
        
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

        // on right click, hide icon
        trayicon.popup_menu.connect( () => { trayicon.set_visible(false); } );
        
        // ON TITLE CHANGED
        aWindow.name_changed.connect( () => { trayicon.set_tooltip_text ( aWindow.get_name()); } );
        aWindow.icon_changed.connect( () => { trayicon.set_from_pixbuf  ( aWindow.get_icon()); } );

    }
  }

  public static int main (string[] args) {
    Gdk.threads_init();
    Gtk.init(ref args);
    
    var app = new UnityAppTray();
    app.init();

//   Gtk.Window window = new Gtk.Window();
//   window.resize(10, 10);
//   window.title = "UnitAppTray-init";
//   window.show();
//
//   Wnck.Screen screen = Wnck.Screen.get_default();
//   screen.window_closed.connect( (aWindow) => { 
//       if(aWindow.get_name() == "UnitAppTray-init") {
//         Gdk.threads_enter();
//    app.init(); 
//        Gdk.threads_leave();
//       }
//   });
//    
//   Timeout.add (100, () => {
//        Gdk.threads_enter();
//        window.hide();
//        Gdk.threads_leave();
//        return false;
//   });
    
    Gdk.threads_enter();
    Gtk.main();
    Gdk.threads_leave();


    return 0;
  }
//}
