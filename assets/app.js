/* Table of Contents:
    1. Init
        1.1 main (background)
    2. Functions
        2.1 logo
        2.2 background*/
/*main*/
background(); /*matching background to the user time + respecting motion*/
/*logo*/
function logo(id, content) {
    if (id.textContent !== content) {
        id.textContent = content;
        id.style.color = "darkcyan";
        document.getElementById(id.id).title = '';
    }
    else {
        id.textContent = id.id;
        id.style.color = "gray";
        document.getElementById(id.id).title = 'click me';
    }
}
/*background*/
function background() {
    var time = new Date();
    var hour = time.getHours();
    if (hour < 6 || hour > 18) {
        if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
            document.body.style.backgroundColor = "darkgray";
        }
        else {
            document.body.style.backgroundImage = "url('assets/background-night.gif')";
        }
    }
    else {
        if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
            document.body.style.backgroundColor = "white";
        }
        else {
            document.body.style.backgroundImage = "url('assets/background-day.gif')";
        }
    }
}
