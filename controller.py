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
import os, youtube_dl, json

# Variables) Globals
scriptDir = os.path.dirname(os.path.realpath(__file__))
musicDir = scriptDir + "/assets/music"

class color:
    GREEN = '\033[32m'
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

# Help)
helpTitle = ("help*", "exit", "list", "load*", "remove*", "play*", "start", "stop", "skip*")
helpTip = ("outputs this message, try 'help [option]'", "exits the controller and sync process", "shows the queued and the loaded songs", "parses songs from youtube, try 'load [song name]'", "removes loaded songs, try 'remove [song]'", "plays loaded songs, try 'play [song]'", "moves songs from the queue to the play-state", "stops streaming to murb", "skips the current song, try 'skip [queue song index]'")

# Startup)
meta = ["queue.json", "current.json"]
if not os.path.isfile(scriptDir + '/assets/meta/queue.json'):
    queueJSON = { "songs": [{ "file": "", "duration": 0 }] }
    currentJSON = { "file": "", "remaining": 0, "duration": 0 }

    with open(scriptDir + '/assets/meta/queue.json', 'w') as createQueue:
        json.dump(queueJSON, createQueue, sort_keys=True, indent=2)
    with open(scriptDir + '/assets/meta/current.json', 'w') as createCurrent:
        json.dump(currentJSON, createCurrent, sort_keys=True, indent=2)

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
                answer = input("\n" + "Enter 'yes' to queue " + color.BOLD + loadedfile + color.END + "\n")
                if answer.lower() == "yes":
                    queue(loadedfile)
                else:
                    print("\n" + "[ " + color.GREEN + "Cancelled" + color.END + " ]")
            else:
                load(song)
    else:
        help("load")

def queue(song):
    with open(scriptDir + '/assets/meta/current.json', 'r') as readCurrent:
        current = json.load(readCurrent)
        #currentSong = current['file']
        #currentDuration = current['duration']
        currentRemaining = current['remaining']

    if currentRemaining == 0:
        with open(scriptDir + '/assets/meta/queue.json', 'r') as readQueue:
            queue = json.load(readQueue)
            nextSong = queue['songs'][0]['file']
            nextDuration = queue['songs'][0]['duration']

            swap = {
                "duration": nextDuration,
                "file": nextSong,
                "remaining": nextDuration
            }    
            
        with open(scriptDir + '/assets/meta/current.json', 'w') as swapCurrent:
            json.dump(swap, swapCurrent, sort_keys=True, indent=2)
    else:
        print("get song length")
        print("append to queue")

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
