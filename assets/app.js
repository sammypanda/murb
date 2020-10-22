"use strict";
/* Table of Contents:
    1. Init
        1.1 main
            1.1a default background state (on)
    2. Functions
        2.1 clientSync()
        2.2 logo()
        2.3 getCookie()
        2.4 background()
        2.5 backgroundToggle()*/
/*main*/
background("on"); /*setting default background and matching to the user time*/
/*clientSync*/
function clientSync() {
    fetch('assets/meta/current.json')
        .then(function (u) {
        return u.json();
    })
        .then(function (json) {
        var playbutton = document.getElementById('playbutton');
        var broadcast = document.getElementById('broadcast');
        var file = decodeURIComponent(json.file);
        var duration = (json.duration - json.remaining); // has an odd 10ish second delay
        var song = new Audio("assets/music/" + file);
        var sync = decodeURIComponent(json.sync);
        if (sync == "off") {
            console.log("Sync: " + sync);
            playbutton.removeAttribute("onclick");
            broadcast.innerHTML = "No broadcast ongoing<br> auto-join is on";
            playbutton.style.color = "darkcyan";
            playbutton.style.cursor = "default";
            playbutton.style.display = "grid";
            setTimeout(function () {
                clientSync();
            }, 1000);
        }
        else {
            song.play().then(function (result) {
                console.log("joined at " + song.currentTime + "/" + json.duration + " seconds of " + file);
                function ongoing() {
                    fetch('assets/meta/current.json')
                        .then(function (u) {
                        return u.json();
                    })
                        .then(function (json) {
                        var sync = decodeURIComponent(json.sync);
                        if (sync == "on") {
                            playbutton.style.display = "none";
                            playbutton.style.color = "darkcyan";
                            broadcast.innerHTML = "Broadcast ongoing";
                            setTimeout(ongoing, 1000);
                        }
                        else if (sync == "off") {
                            song.pause();
                            broadcast.innerHTML = "No broadcast ongoing";
                            playbutton.style.display = "grid";
                            playbutton.style.color = "gray";
                            clientSync();
                        }
                        else {
                            broadcast.innerHTML = "Update the controller:<br>'sync state not found or corrupt'";
                            ongoing();
                        }
                    });
                }
                ongoing();
            }, function (error) {
                broadcast.innerHTML = "No broadcast ongoing";
                playbutton.style.display = "grid";
                playbutton.style.color = "gray";
                playbutton.setAttribute("onclick", 'clientSync()');
            });
            song.currentTime = duration; // debuggies - appears slower than controller
        }
    });
}
/*logo()*/
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
/*getCookie()*/
function getCookie(name) {
    var result = document.cookie.match("(^|[^;]+)\\s*" + name + "\\s*=\\s*([^;]+)");
    return result ? result.pop() : "";
}
/*background()*/
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
/*backgroundToggle()*/
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
