valac --pkg=gee-1.0 --pkg=gtk+-2.0 --pkg=libwnck-1.0 --Xcc='-DWNCK_I_KNOW_THIS_IS_UNSTABLE' UnityAppTray.vala \
&& echo invoked && ./UnityAppTray

