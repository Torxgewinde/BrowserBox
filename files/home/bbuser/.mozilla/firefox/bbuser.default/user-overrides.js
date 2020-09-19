/**
 *
 * BrowserBox, a Virtualbox-VM with Firefox preinstalled and preconfigured
 * 
 * (c) 2020 Tom Stöveken
 * 
 * License: GPLv3 ff
 * 
 * This file overrides settings made by arkenfox by appending this file
 * to the end of user.js when arkenfox creates or updates the file
 * 
 */

user_pref("_user.js.parrot", "the parrot might have been reborn?");

/** Firefox starts at fullscreen within the Virtualbox window, to still
 * keep important items visible use these settings */
user_pref("browser.fullscreen.autohide", false);
user_pref("browser.tabs.closeWindowWithLastTab", false);

user_pref("browser.startup.page", 3);
user_pref("browser.startup.homepage", "https://www.startpage.com/do/mypage.pl?prfh=connect_to_serverEEEeuN1Ndisable_family_filterEEE1N1Ndisable_open_in_new_windowEEE0N1Ndisable_video_family_filterEEE1N1Nenable_post_methodEEE1N1Nenable_proxy_safety_suggestEEE0N1Nenable_stay_controlEEE0N1Ngeo_mapEEE1N1Nlang_homepageEEEs%2Fblak%2Fde%2FN1NlanguageEEEenglishN1Nlanguage_uiEEEdeutschN1Nnum_of_resultsEEE20N1Nother_iaEEE1N1Nsearch_results_regionEEEallN1NsuggestionsEEE1N1Nwikipedia_iaEEE1N1Nwt_unitEEEcelsius");
user_pref("keyword.enabled", true);
user_pref("places.history.enabled", true);
user_pref("signon.rememberSignons", true);
user_pref("security.password_lifetime", 30);
user_pref("browser.sessionstore.resume_from_crash", true);
user_pref("browser.shell.shortcutFavicons", true);
user_pref("media.peerconnection.enabled", true);
user_pref("browser.download.folderList", 1);
user_pref("privacy.clearOnShutdown.history", false);

user_pref("browser.search.update", true);

user_pref("extensions.pocket.enabled", false);
user_pref("identity.fxaccounts.enabled", false);

/** remove white border showing for unusual resolutions,
 * this is against fingerprinting based on screen size, but this
 * fingerprintable feature can remain */
user_pref("privacy.resistFingerprinting.letterboxing", false);

/** documentation found at:
 * https://extensionworkshop.com/documentation/enterprise/enterprise-distribution/#controlling-automatic-installations 
 * 1 (or '0b0001') 	The current user’s profile.
 * 2 (or '0b0010') 	All profiles of the logged-in user.
 * 4 (or '0b0100') 	Installed and owned by Firefox.
 * 8 (or '0b1000') 	Installed for all users of the computer. */
user_pref("extensions.enabledScopes", 15);
user_pref("extensions.autoDisableScopes", 0);


user_pref("_user.js.parrot", "the parrot became alive again!");
