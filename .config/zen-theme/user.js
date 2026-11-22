// Zen preferences, linked into your profile by browser/zen-install.sh.
// Zen applies them at every start (a change here wins over the settings UI).
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true); // load userChrome.css
user_pref("zen.widget.linux.transparency", true);                     // see-through window; Hyprland blurs it
user_pref("browser.tabs.allow_transparent_browser", true);            // needed for the transparency
