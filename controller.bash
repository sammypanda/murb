# Table of Contents:
    #1 Variables
        #1a Globals
        #1b Syncing
        #1c Load
        #1d Help
    #2 Dependencies
        #2a Youtube-DL
        #2b JQ
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
        #3j trapsxoxo()

# Variables) Globals
script=$(readlink -f "$0")
scriptDir=$(dirname "$script")
musicDir="$scriptDir/assets/music"

# Variables) Syncing
current="$scriptDir/assets/meta/current.json"; queue="$scriptDir/assets/meta/queue.json"

if [[ `jq '.volume' $current` ]]; then
    volume=`jq '.volume' $current | xargs echo -n`
else
    if [ -z ${originalvolume+x} ]; then 
        originalvolume="1" && volume="1"
    else
        volume=$originalvolume
    fi
fi

# Variables) Load
mp3dl="youtube-dl -x --audio-format mp3 -o "$scriptDir/"'%(title)s.%(ext)s'"

# Variables) Help
help=("help*" "exit" "list" "load*" "remove*" "play*" "start" "stop" "skip*" "volume*")
tip=("outputs this message, try 'help [option]'" "exits the controller and sync process" "shows the queued and the loaded songs" "parses songs from youtube, try 'load [song name]'" "removes loaded songs, try 'remove [song]'" "plays loaded songs, try 'play [song]'" "moves songs from the queue to the play-state" "stops streaming to murb" "skips the current song, try 'skip [queue song index]'" "adjusts the volume of the current song, try 'volume [0-10]' (default 1)")

# Dependencies) Youtube-DL
if ! [[ -f /usr/bin/youtube-dl ]]; then
    if [[ apt ]]; then
        sudo apt-get install -y python ffmpeg
    fi
    if [[ eopkg ]]; then
        sudo eopkg install -y python ffmpeg
    fi
    sudo curl -L https://yt-dl.org/downloads/latest/youtube-dl -o /usr/bin/youtube-dl
    sudo chmod a+rx /usr/bin/youtube-dl
    youtube-dl -U
fi

# Dependencies) JQ
if ! [[ -f /usr/bin/jq ]]; then
    if [[ apt ]]; then
        sudo apt-get install -y jq
    fi
    if [[ eopkg ]]; then
        sudo eopkg install -y jq
    fi
fi

# Functions
function syncActivity() {
    if [[ ! -f $current ]]; then
        touch $current
	touch $queue
    fi

    if [[ `jq -r '.sync' $current` == "on" ]]; then # Parameter 'jq -r' (raw) removes quotations from output
        echo -e "[sync active at $(tput setaf 4)murb/.sync.log$(tput sgr0)]\n"
    else
        echo -e "[$(tput setaf 1)sync inactive$(tput sgr0)]\n"
    fi
}

function song() {
    state=$1; directory=$2; file=$3; param=$4
    if [[ `echo "$file" | grep -w "\-y"` ]]; then # If the file has the -y parameter
        param="-y"
        file=`echo "${file%-y}" | xargs echo -n`
    fi
    if [ "$file" == "*" ]; then
        playMultiple "$musicDir" "$param"
        return
    fi
    if [[ ! $file ]]; then
        echo -e "[$(tput setaf 1)please input song title$(tput sgr0)]\n"
    else
        targetFile=`ls $directory | grep -i -m1 -F "${file}"` # Find a matching file to input
        if [[ $targetFile ]]; then
            if [ "$param" == "-y" ]; then
                answer="yes"
            else
                read -p "Enter 'yes' to $state $(tput bold)$targetFile$(tput sgr0): " answer
            fi
            if [[ `echo $answer | tr [:upper:] [:lower:]` == "yes" ]]; then # Translates $answer to lowercase
                if [[ $state == "remove" ]]; then
                    rm "$directory/$targetFile"
                    echo -e "[$(tput setaf 2)deleted$(tput sgr0)]\n"
                elif [[ $state == "play" ]]; then
                    queue "$targetFile"
                fi
            elif [[ `echo $answer | tr [:upper:] [:lower:]` == "cancel" ]]; then
                return 1
            else
                echo -e "[$(tput setaf 1)cancelled$(tput sgr0)]\n"
            fi
        else
            echo -e "[$(tput setaf 1)unable to find song$(tput sgr0)]\ntry 'list'\n"
        fi
    fi
}

function list() {
    echo -e "$(tput bold)loaded:$(tput sgr0) \n`ls $musicDir`\n"
    if [[ `jq .remaining $current -r` -gt 0 ]]; then
        if [[ `jq .sync $current -r` == "on" ]]; then
            echo -e "$(tput bold)current:$(tput sgr0) \n`jq .file $current -r` @ `jq .remaining $current -r` seconds remaining\n"
        else
            echo -e "$(tput bold)paused:$(tput sgr0) \n`jq .file $current -r` @ `jq .remaining $current -r` seconds remaining\n"
        fi
    fi
    if [[ ! `jq .songs[0].file $queue` == null ]]; then
        echo -e "$(tput bold)queued:$(tput sgr0)"
        IFS=$'\n' # foreach loops separate newline instead of whitespace
        i=1
        for song in `jq '.songs[].file' $queue -r`; do
            echo "$i. $song"
            i=$((i+1))
        done
        unset i
        unset IFS
        echo -e
    fi
}

function help() {
    option=$1
    option=`echo $option | tr [:upper:] [:lower:]`
    if [[ ! $option ]]; then
        option="help"
    fi
    i=0; for each in ${help[@]}
    do
        if [[ $option == ${help[i]} ]]; then # Only producing the correct help information
            savedOption=${help[i]} # Saving the option for later
            help[i]="$(tput bold)${help[i]}$(tput sgr0)" # Adjusting the array to make the current option bold
            echo -e "${help[@]}\n$(tput dim)- ${tip[i]}$(tput sgr0)\n" # Outputting the modified array and the matching tip
            help[i]="$savedOption" # Returning the array to normal
        fi
        ((i++))
    done
}

function load() {
    query=$1
    url=`echo $query | grep 'http\|youtube.com'`
    if ! [[ $url ]]; then
        if [[ $query ]]; then
            echo $query
            $mp3dl "ytsearch:$query" # Temporarily store the song in the root
            file=`ls "$scriptDir" | grep ".mp3"` # Find the song
            if [[ $file ]]; then
                echo $musicDir
                mv "$scriptDir/$file" "$musicDir" # Move to correct place
                echo -e "\n[stored $(tput setaf 4)$file$(tput sgr0)]\n"
                read -p "Enter 'yes' to queue $(tput bold)$file$(tput sgr0): " answer
                if [[ `echo $answer | tr [:upper:] [:lower:]` == "yes" ]]; then
                    queue "$file"
                fi
            else # Retry until the JSON parse works (yt-dl issue)
                load "$query"
            fi
            clear
        else
            echo -e "load $(tput setaf 1)[name/url]$(tput sgr0)\n"
        fi
    else
        echo "(please only use titles for searching)"
        echo -e "load $(tput setaf 1)[name/url]$(tput sgr0)\n"
    fi
}

function queue() {
    song=$1
    hours="10#"`ffmpeg -i "$musicDir/$song" 2>&1 | grep Duration: | cut -c13-14`
    minutes="10#"`ffmpeg -i "$musicDir/$song" 2>&1 | grep Duration: | cut -c16-17`
    seconds="10#"`ffmpeg -i "$musicDir/$song" 2>&1 | grep Duration: | cut -c19-20`
    duration=$(( hours * 3600 + minutes * 60 + seconds ))
    if [[ ! -f "$current" ]] || [[ `cat $current | jq -r '.remaining'` == "0" ]]; then
        echo "{\"file\": \"$song\", \"remaining\": \"$duration\", \"duration\": \"$duration\"}" | jq . > $current
        echo -e "\n[playing $(tput setaf 4)$song$(tput sgr0)]\n"
        syncProcess "on"
    else
        if [[ ! -f "$queue" ]] || [[ `cat $queue | jq -r '.file'` == "" ]]; then
            echo "{\"songs\": [{\"file\": \"$song\", \"duration\": \"$duration\"}]}" | jq . > $queue
            echo -e "\n[created queue with $(tput setaf 4)$song$(tput sgr0)]\n"
        else
            cat <<< $(jq ".songs += [{\"file\": \"$song\", \"duration\": \"$duration\"}]" $queue) > $queue
            echo -e "\n[queued $(tput setaf 4)$song$(tput sgr0)]\n"
        fi
    fi
}

function syncProcess() {
    kill $sync_pid &> /dev/null
    unset sync_pid
    if [[ $1 == "on" ]]; then
        while [[ "`jq '.sync' $current`" == "\"off\"" ]]; do
            cat <<< $(jq '.sync = "on"' $current) > $current
        done
        cat <<< $(jq '.sync = "on"' $current) > $current
        sync > .sync.log 2>&1 &
        sync_pid=$!
        echo -e "[started sync at $(tput setaf 4)./.sync.log$(tput sgr0)]\n"
    elif [[ $1 == "off" ]]; then
        while [[ `jq '.sync' $current` == \"on\" ]]; do
            cat <<< $(jq '.sync = "off"' $current) > $current
        done
        echo -e "[$(tput setaf 1)stopped sync$(tput sgr0)]\n"
    fi
}

function sync() {
    while true; do
        cat <<< $(jq '.sync = "on"' $current) > $current
        cat <<< $(jq --arg volume $originalvolume '.volume = $volume' $current) > $current # Update volume
        if [[ `cat $current | jq -r '.remaining'` -gt 0 ]]; then # The current song is still active
            time=`cat $current | jq -r '.remaining'`
            file=`jq -r '.file' $current`
            if [[ `cat $current | jq -r '.duration'` == $time ]]; then
                echo -e "\n[playing $(tput setaf 4)$file$(tput sgr0)]\n"
            else
                echo -e "\n[resuming $(tput setaf 4)$file$(tput sgr0)]\n"
            fi
            while [[ $time -ge 0 ]]; do
                sleep 1 &
                echo $time # Output seconds in .sync.log
                cat <<< $(jq --arg time $time '.remaining = $time' $current) > $current # Update time
                time=$(($time - 1))
                wait $!
            done
        else # The current song has finished
            file=`jq -r '.songs[0].file' $queue`
            duration=`jq -r '.songs[0].duration' $queue`
            if [[ ! $file == null ]]; then # A song was found in the queue
                echo "{\"file\": \"$file\", \"remaining\": \"$duration\", \"duration\": \"$duration\"}" | jq . > $current # Move queue song to current song
                echo -e "\n[playing $(tput setaf 4)$file$(tput sgr0)]\n"
                cat <<< $(jq 'del(.songs[0])' $queue) > $queue # Remove new current song from the queue
            else # No song was found in queue
                echo -e "\n[reached $(tput setaf 1)end of queue$(tput sgr0)]\n"
                syncProcess "off" # End the sync
                break # Break the while loop
            fi
            kill $sync_pid
            unset sync_pid
        fi
    done
}

function skip() {
    selection=$1
    index=$((selection - 1))
    number='^[0-9]+$' # Regex for accepting only numerical characters
    if [[ $selection == "" ]] || [[ $selection == 0 ]]; then
        if [[ `jq -r '.sync' $current` == "on" ]]; then
            syncProcess "off"
            sleep 2s
            cat <<< $(jq '.remaining = 0' $current) > $current
            echo -e "[skipped $(tput setaf 4)`jq '.file' $current`$(tput sgr0)]\n"
            sleep 2s
            syncProcess "on"
        else
            cat <<< $(jq '.remaining = 0' $current) > $current
            echo -e "[skipped $(tput setaf 4)`jq '.file' $current`$(tput sgr0)]\n"
        fi
    elif [[ $selection =~ $number ]]; then
        selectionSong=`jq --arg index $index -r '.songs[$index|tonumber].file' $queue`
        cat <<< $(jq --arg index $index 'del(.songs[$index|tonumber])' $queue) > $queue
        echo -e "[skipped $(tput setaf 4)$selectionSong$(tput sgr0)]\n"
    else
        echo -e "skip $(tput setaf 1)[index]$(tput sgr0)\n"
    fi
}

function playMultiple() {
    list=$1; param=$2
    for dir in $musicDir/*; do
        cancel=$? # return 0 = continue, return 1 = cancel
        if [ $cancel -ne 0 ]; then
            break
        else
            song "play" "$musicDir" "${dir#$musicDir"/"}" "$param"
        fi
    done
}

function volume() {
    value=$1
    if [[ `jq '.sync' $current` == \"on\" ]]; then
        if [[ $value =~ ^[+-]?[0-9]+$ ]] && [ $value -le 10 ]; then
            volume=$value
            originalvolume=$value # Update the oldie that initiated the volume field originally
            echo -e "[$(tput setaf 4)volume set to $(tput sgr0)$volume/10]\n"
            cat <<< $(jq --arg volume $value '.volume = $volume' $current) > $current # Update volume
        elif ! [[ $value ]]; then
            echo -e "[$(tput setaf 4)the volume is currently $(tput sgr0)$volume/10]\n\nvolume $(tput setaf 1)[0-10]$(tput sgr0)\n"
        else
            echo -e "[$(tput setaf 1)volume out of bounds (0-10)$(tput sgr0)]\n"
        fi
    else 
        echo -e "[$(tput setaf 1)nothing is playing, try 'start'$(tput sgr0)]\n"
    fi
}

function trapsxoxo() {
    syncProcess "off" || cat <<< $(jq '.sync = "off"' $current) > $current
    rm -f $scriptDir/*{mp3,webm,m4a,part,ytdl}*
    exit
}

# Main
trap trapsxoxo 2 20 # 2 = CTRL+C | 20 = CTRL+Z
while true; do
    syncActivity
    read -p "command: " input
    clear
    case $input in
        exit)
            trapsxoxo
        ;;
        help*)
            help "`echo "${input#help}" | xargs echo -n`" # The regex removes 'help' from the input
        ;;
        list|ls)
            list
        ;;
        remove*)
            song "remove" "$musicDir" "`echo ${input#remove} | xargs echo -n`" # The xarg removes leading and trailing whitespace
        ;;
        load*)
            load "${input#load}"
        ;;
        play*)
            song "play" "$musicDir" "`echo "${input#play}" | xargs echo -n`"
        ;;
        start)
            syncProcess "on"
        ;;
        stop)
            syncProcess "off"
        ;;
        skip*)
            skip "`echo ${input#skip} | xargs echo -n`"
        ;;
        volume*)
            volume "`echo ${input#volume} | xargs echo -n`"
        ;;
        *)
            echo -e "[$(tput setaf 1)unknown command$(tput sgr0)]\ntry 'help'\n"
        ;;
    esac
done
