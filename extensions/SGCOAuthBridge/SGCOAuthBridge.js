var sgcOAuthPopupWindow = null;
window.__sgcOauthBridgeLoaded = true;

window.sgc_browser_get_url = function() {
    try {
        return window.location.href || "";
    } catch (error) {
        return "";
    }
};

window.sgc_oauth_popup_open = function(_url) {
    var targetUrl = String(_url || "");
    if (targetUrl === "") {
        return 0;
    }

    var specs = "popup=yes,width=520,height=760,location=yes,menubar=no,toolbar=no,status=no,resizable=yes,scrollbars=yes";
    try {
        sgcOAuthPopupWindow = window.open(targetUrl, "sgc_oauth_popup", specs);
        if (sgcOAuthPopupWindow && !sgcOAuthPopupWindow.closed) {
            try {
                sgcOAuthPopupWindow.focus();
            } catch (error) {}
            return 1;
        }
    } catch (error) {}

    try {
        window.location.assign(targetUrl);
    } catch (error) {
        window.location.href = targetUrl;
    }
    return 0;
};

window.sgc_oauth_popup_focus = function() {
    try {
        if (sgcOAuthPopupWindow && !sgcOAuthPopupWindow.closed) {
            sgcOAuthPopupWindow.focus();
            return 1;
        }
    } catch (error) {}
    return 0;
};
