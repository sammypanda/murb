/* Table of Contents:
    1. Init
        1.1 main
            1.1a background("on") - updates theme and sets default to on
            1.1c element shortcuts
            1.1d error catch counter
    2. Functions
        2.1 checkSync()
        2.2 clientSync()
        2.3 logo()
        2.4 getCookie()
        2.5 background()
        2.6 backgroundToggle()
    3. Utils
        3.1 removeExt() */
    
/*main*/
background("on");
checkSync();
var playbutton = document.getElementById('playbutton')!;
var broadcast = document.getElementById('broadcast')!;
var song = new Audio();
var oopsies = 0
var hangingvolume = 1

function checkSync() { // doubles as auto-join
    fetch('assets/meta/current.json')
    .then(file => {
        return file.json();
    })
    .then(current => {
        var messagePart = broadcast.innerHTML.split(" ");
        if (current.sync == "on") {
            if (messagePart[1] == "ongoing" || messagePart[0] == "No" || messagePart[2] == "host" || messagePart[0] == "Uh-oh,") {
                broadcast.innerHTML = "Broadcast ongoing <br> " + removeExt(current.file);
            }
        } else if (current.sync == "off") {
            if (messagePart[3] !== "auto-join") {
                broadcast.innerHTML = "No broadcast ongoing";
            }
        }
    })
    .catch(error => {
        var messagePart = broadcast.innerHTML.split(" ");
        if (messagePart[1] !== "corrupted") {
            broadcast.innerHTML = "Uh-oh, check the host is running controller.bash";
        }
    });
    setTimeout(checkSync, 10000);
}

/*clientSync*/
function clientSync() {
    fetch('assets/meta/current.json')
    .then(file => {
        return file.json();
    })
    .then(current => {
        if (song.id !== "currentSong") {
            var duration = (current.duration - current.remaining);
            if (song) {
                song.src = "assets/music/" + current.file;
                song.load();
                song.currentTime = duration;
            } else {
                song = new Audio("assets/music/" + current.file);
                song.id = "currentSong";
                song.currentTime = duration;
            }
        }

        if (current.sync == "off") {
            song.pause
            oopsies = 0;
            console.log("Sync: %coff", "color: palevioletred");
            broadcast.innerHTML = "No broadcast ongoing<br> auto-join is on, reload to turn off";
            playbutton.removeAttribute('onclick');
            playbutton.style.color = "darkcyan";
            playbutton.style.cursor = "default";
            playbutton.style.display = "grid";
            setTimeout(clientSync, 500); // sets a constant reset
        } else if (current.sync == "on") {
            song.play().then(result => {
                song.volume = (current.volume / 10) // Removes audio jank
                playbutton.style.display = "none";
                broadcast.innerHTML = "Broadcast joined <br> " + removeExt(current.file);
                console.info("%cjoined at " + song.currentTime + "/" + current.duration + " seconds of " + current.file, "font-weight: 700");
                function ongoing() { // keeps checking sync status once sync is seen as on
                    fetch('./assets/meta/current.json')
                    .then(file => {
                        return file.json();
                    })
                    .then(current => {
                        if (current.sync == "on") {
                            console.log("Sync: %con", "color: lightgreen");
                            console.log("%cclient: " + (song.duration - song.currentTime) + "s", "color: gray; font-weight: 100")
                            console.log("%cserver: " + current.remaining + "s", "color: gray; font-weight: 100")
                            if ((current.volume / 10) !== hangingvolume) {
                                song.volume = (current.volume / 10); // Auto-updating
                                console.info("%cserver volume " + current.volume + "/10", "color: gray; font-weight: 900")
                                hangingvolume = song.volume
                            }
                            oopsies = 0;
                            setTimeout(ongoing, 1000);
                        } else if (current.sync == "off") {
                            oopsies = 0;
                            song.pause();
                            clientSync();
                        }
                        song.onended = () => {
                            oopsies = 0;
                            song.pause();
                            clientSync();
                        }
                    })
                    .catch((error) => {
                        console.log("%c[smol json oopsie-doopsie]", "color: lightpink; font-weight: 700");
                        if (oopsies >= 16) {
                            window.location.reload(false);
                        } else {
                            oopsies+=1;
                            setTimeout(ongoing, 1000);
                        }
                    });
                }
                setTimeout(ongoing, 2000); // triggering the sync status check
            });
        } else {
            clientSync();
        }
    })
    .catch((error) => {
        console.log("%c[big json oopsie-doopsie]", "color: lightpink; font-weight: 700");
        broadcast.innerHTML = "Broadcast corrupted";
        playbutton.style.color = "darkcyan";
        playbutton.style.cursor = "default";
        if (oopsies == 6) {
            window.location.reload(false);
        } else {
            oopsies+=1;
            setTimeout(clientSync, 1000);
        }
    });
}

/*logo()*/
function logo(id: HTMLElement, content: string) {
    if (id.textContent !== content) {
        id.textContent = content;
        id.style.color = "darkcyan";
        id.title = '';
    } else {
        id.textContent = id.id;
        id.style.color = "gray";
        id.title = 'click me';
    }
}

/*getCookie()*/
function getCookie(name: string) {
    let result = document.cookie.match("(^|[^;]+)\\s*" + name + "\\s*=\\s*([^;]+)")
    return result ? result.pop() : ""
}

/*background()*/
function background(state: string) {
    var time = new Date();
    var hour = time.getHours();
    
    if (hour < 6 || hour > 18) {
        var background = ["url(assets/images/background-night.gif)","#101010"];
    } else {
        var background = ["url(assets/images/background-day.gif)","white"];
    }
        
    if (state == "off" || getCookie("bg_state") == "off" || window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
        document.body.style.backgroundColor = background[1];
        document.body.style.backgroundImage = "url(#)";
    } else if (state == "on" || getCookie("bg_state") == "on") {
        document.body.style.backgroundImage = background[0];
        document.body.style.backgroundColor = "";
    }
}

/*backgroundToggle()*/
function backgroundToggle() {
    if (document.body.style.backgroundColor == "") {
        document.cookie = "bg_state=off";
        background("off");
    } else {
        document.cookie = "bg_state=on";
        background("on");
    }
}

/*trackName()*/
function trackName() {
    fetch('assets/meta/current.json')
        .then(function (file) {
        return file.json();
    })
        .then(function (current) {
        current.file = removeExt(current.file)

        if (current.sync == "on") {
            document.getElementsByTagName('p')[0].innerHTML = current.file;
        }
        else {
            document.getElementsByTagName('p')[0].innerHTML = "Nothing Playing";
        }
    });
    setTimeout(trackName, 2000);
}
if (document.title == "Current Murb Track") {
    trackName();
}

var music = document.querySelector("#mu")!;
var curb = document.querySelector("#rb")!;

[music, curb].forEach((logoPart) => {
    logoPart.addEventListener('click', (e) => {
        window.location.href = "https://github.com/Samdvich/murb";
    });
});

/*removeExt()*/
function removeExt(track: string) {
    var noext = track.split('.')
    noext.splice(-1)
    return noext
}