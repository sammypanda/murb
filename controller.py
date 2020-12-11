# Table of Contents:
    #1 Variables
        #1a Globals
        #1c Help
    #3 Functions
        #3a syncActivity()
        #3b song()
        #3c list()
        #3d help()
        #3e load()
        #3f queue()
        #3g syncProcess()
        #3h sync()
        #3i skip()

# Imports) Globals
import os, youtube_dl

# Variables) Globals
scriptDir = os.path.dirname(os.path.realpath(__file__))
musicDir = scriptDir + "/assets/music"

class color:
    RED = '\033[31m'
    BOLD = '\033[1m'
    END = '\033[0m'

def ytdl_hook(d):
    if d['status'] == 'finished':
        global loadedfile
        loadedfile = d['filename']

# Options) Globals
ytdl_opts = {
    'format': 'bestaudio/best',
    'outtmpl': (musicDir + '/%(title)s.%(ext)s'),
    'default_search': 'ytsearch',
    'postprocessors': [{
        'key': 'FFmpegExtractAudio',
        'preferredcodec': 'mp3',
    }],
    'progress_hooks': [ytdl_hook],
}

# Menu) Help
helpTitle = ("help*", "exit", "list", "load*", "remove*", "play*", "start", "stop", "skip*")
helpTip = ("outputs this message, try 'help [option]'", "exits the controller and sync process", "shows the queued and the loaded songs", "parses songs from youtube, try 'load [song name]'", "removes loaded songs, try 'remove [song]'", "plays loaded songs, try 'play [song]'", "moves songs from the queue to the play-state", "stops streaming to murb", "skips the current song, try 'skip [queue song index]'")

# Functions)
def help(option=""):
    if option:
        option = option.lower()
    else:
        option = "help"

    i = 0
    for each in helpTitle:
        if option == each.replace('*',''):
            print(color.BOLD + each + " - " + helpTip[i] + color.END)
        else:
            print(each)
        i = i + 1

def exit():
    for file in os.listdir(scriptDir):
        if file.endswith(tuple([".ytdl", ".webm", ".m4a", ".part"])):
            os.remove(file)
    quit()

def load(song):
    if song:
        with youtube_dl.YoutubeDL(ytdl_opts) as ytdl:
            ytdl.download([song])
            if 'loadedfile' in globals():
                print(loadedfile)
            else:
                load(song)
    else:
        help("load")

while True:
    print()
    command = input("command: ")
    if os.name == 'nt':
        os.system('cls')
    else:
        os.system('clear') 

    if "help" in command:
        help(command.replace('help','').strip())
    elif "exit" in command:
        exit()
    elif "load" in command:
        load(command.replace('load','').strip())
    else:
        print("[ " + color.RED + "Unknown Command" + color.END + " ]" + "\n")
        help()