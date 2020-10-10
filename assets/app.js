"use strict";
/* Table of Contents:
    1. Init
        1.1 main (background)
            1.1a default background state (on)
    2. Functions
        2.1 logo
        2.2 cookies
        2.3 background
        2.4 backgroundToggle*/
/*main*/
background("on"); /*setting default background and matching to the user time*/
/*logo*/
function logo(id, content) {
    if (id.textContent !== content) {
        id.textContent = content;
        id.style.color = "darkcyan";
        id.title = '';
    }
    else {
        id.textContent = id.id;
        id.style.color = "gray";
        id.title = 'click me';
    }
}
/*cookies*/
function getCookie(name) {
    var result = document.cookie.match("(^|[^;]+)\\s*" + name + "\\s*=\\s*([^;]+)");
    return result ? result.pop() : "";
}
/*background*/
function background(state) {
    var time = new Date();
    var hour = time.getHours();
    if (hour < 6 || hour > 18) {
        var background = ["url(assets/images/background-night.gif)", "#101010"];
    }
    else {
        var background = ["url(assets/images/background-day.gif)", "white"];
    }
    if (state == "off" || getCookie("bg_state") == "off" || window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
        document.body.style.backgroundColor = background[1];
        document.body.style.backgroundImage = "url(#)";
    }
    else if (state == "on" || getCookie("bg_state") == "on") {
        document.body.style.backgroundImage = background[0];
        document.body.style.backgroundColor = "";
    }
}
/*backgroundToggle*/
function backgroundToggle() {
    if (document.body.style.backgroundColor == "") {
        document.cookie = "bg_state=off";
        background("off");
    }
    else {
        document.cookie = "bg_state=on";
        background("on");
    }
}
