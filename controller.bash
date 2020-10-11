# Table of Contents:
    #1 Variables
        #1a Globals
        #1b Load
        #1c Help
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
musicDir="./assets/music"

# Variables) Load
mp3dl="youtube-dl -x --audio-format mp3 -o '%(title)s.%(ext)s'"

# Variables) Help
help=("help*" "exit" "list" "load*" "remove*" "play*" "start" "stop" "skip*")
tip=("outputs this message, try 'help [option]'" "exits the controller and sync process" "shows the queued and the loaded songs" "parses songs from youtube, try 'load [song name]'" "removes loaded songs, try 'remove [song]'" "plays loaded songs, try 'play [song]'" "moves songs from the queue to the play-state" "stops streaming to murb" "skips the current song, try 'skip [queue song index]'")

# Variables) Syncing
current="./assets/meta/current.json"; queue="./assets/meta/queue.json"

# Dependencies) Youtube-DL
if ! [[ `pip3 show youtube-dl` ]]; then
    sudo apt-get install pip3
    pip3 install youtube-dl
    sudo apt-get install ffmpeg
fi

# Dependencies) JQ
if ! [[ `dpkg -s jq` ]]; then
    sudo apt-get install jq
fi

# Functions
function syncActivity() {
    if [[ `jq -r '.sync' $current` == "on" ]]; then
        echo -e "[sync active at $(tput setaf 4)./.sync.log$(tput sgr0)]\n"
    else
        echo -e "[$(tput setaf 1)sync inactive$(tput sgr0)]\n"
    fi
}

function song() {
    state=$1; directory=$2; file=$3
    syncActivity
    if [[ ! $file ]]; then
        echo -e "[$(tput setaf 1)please input song title$(tput sgr0)]\n"
    else
        targetFile=`ls $directory | grep -i -m1 "$file"` # Find a matching file to input
        if [[ $targetFile ]]; then
            read -p "Enter 'yes' to $state $(tput bold)$targetFile$(tput sgr0): " answer
            if [[ `echo $answer | tr [:upper:] [:lower:]` == "yes" ]]; then # Translates $answer to lowercase
                if [[ $state == "remove" ]]; then
                    rm "$directory/$targetFile"
                    echo -e "[$(tput setaf 2)deleted$(tput sgr0)]\n"
                elif [[ $state == "play" ]]; then
                    queue "$targetFile"
                fi
            else
                echo -e "[$(tput setaf 1)cancelled$(tput sgr0)]\n"
            fi
        else
            echo -e "[$(tput setaf 1)unable to find song$(tput sgr0)]\ntry 'list'\n"
        fi
    fi
}

function list() {
    syncActivity
    echo -e "$(tput bold)loaded:$(tput sgr0) \n`ls ./assets/music`\n"
    echo -e "$(tput bold)playing:$(tput sgr0) \n`jq .file $current -r` @ `jq .remaining $current -r` seconds\n"
    echo -e "$(tput bold)queued:$(tput sgr0) \n`jq '.songs[].file' $queue -r`\n"
}

function help() {
    option=$1
    syncActivity
    option=`echo $option | tr [:upper:] [:lower:]` # Translates $option to lowercase
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
    if [[ $query ]]; then
        echo $query
        $mp3dl "ytsearch:$query" # Temporarily store the song in the root
        file=`ls | grep ".mp3"` # Find the song
        if [[ $file ]]; then
            mv "$file" ./assets/music # Move to correct place
            echo -e "\n[stored $(tput setaf 4)$file$(tput sgr0)]\n"
            read -p "Enter 'yes' to queue $(tput bold)$file$(tput sgr0): " answer
            if [[ `echo $answer | tr [:upper:] [:lower:]` == "yes" ]]; then
                queue "$file"
            fi
        else
            echo -e "[$(tput setaf 1)cancelled$(tput sgr0)]\n"
        fi
    else
        echo -e "load $(tput setaf 1)[name/url]$(tput sgr0)\n"
    fi
}

function queue() {
    song=$1
    minutes="10#"`ffmpeg -i ./assets/music/"$song" 2>&1 | grep Duration: | cut -c16-17`
    seconds="10#"`ffmpeg -i ./assets/music/"$song" 2>&1 | grep Duration: | cut -c19-20`
    duration=$(( minutes * 60 + seconds ))
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
    if [[ $1 == "on" ]]; then
        sync > .sync.log 2>&1 &
        sync_pid=$!
        echo -e "[started sync at $(tput setaf 4)./.sync.log$(tput sgr0)]\n"
    elif [[ $1 == "off" ]]; then
        if [[ $sync_pid ]]; then
            kill $sync_pid
            echo -e "[$(tput setaf 1)stopped sync$(tput sgr0)]\n"
        fi
        cat <<< $(jq '.sync = "off"' $current) > $current
    fi
}

function sync() {
    cat <<< $(jq '.sync = "on"' $current) > $current
    while true; do
        if [[ ! `cat $current | jq -r '.remaining'` == "0" ]]; then
            time=`cat $current | jq -r '.remaining'`
            file=`jq -r '.file' $current`
            if [[ `cat $current | jq -r '.duration'` == $time ]]; then
                echo -e "\n[playing $(tput setaf 4)$file$(tput sgr0)]\n"
            else
                echo -e "\n[resuming $(tput setaf 4)$file$(tput sgr0)]\n"
            fi
            while [[ $time -ge 0 ]]; do
                echo $time
                cat <<< $(jq --arg time $time '.remaining = $time' $current) > $current
                time=$(($time - 1))
                sleep 1s
            done
        else
            file=`jq -r '.songs[0].file' $queue`
            duration=`jq -r '.songs[0].duration' $queue`
            if [[ ! $file == null ]]; then
                echo "{\"file\": \"$file\", \"remaining\": \"$duration\", \"duration\": \"$duration\"}" | jq . > $current
                echo -e "\n[playing $(tput setaf 4)$file$(tput sgr0)]\n"
                cat <<< $(jq 'del(.songs[0])' $queue) > $queue
            else
                echo -e "\n[reached $(tput setaf 1)end of queue$(tput sgr0)]\n"
                syncProcess "off"
                break
            fi
        fi
    done
}

function skip() {
    selection=$1
    index=$((selection - 1))
    number='^[1-9]+$'
    syncActivity
    if [[ $selection =~ $number ]]; then
        selectionSong=`jq --arg index $index -r '.songs[$index|tonumber].file' $queue`
        cat <<< $(jq --arg index $index 'del(.songs[$index|tonumber])' $queue) > $queue
        echo -e "[skipped $(tput setaf 4)$selectionSong$(tput sgr0)]\n"
    elif [[ $selection == "" ]] || [[ $selection == 0 ]]; then
        if [[ `jq -r '.sync' $current` == "on" ]]; then 
            syncProcess "off"
            cat <<< $(jq '.remaining = 0' $current) > $current
            echo -e "[skipped $(tput setaf 4)`jq '.file' $current`$(tput sgr0)]\n"
            syncProcess "on"
        else
            cat <<< $(jq '.remaining = 0' $current) > $current
            echo -e "[skipped $(tput setaf 4)`jq '.file' $current`$(tput sgr0)]\n"
        fi
    else
        echo -e "skip $(tput setaf 1)[index]$(tput sgr0)\n"
    fi
}

function trapsxoxo() {
    syncProcess "off"
    if [[ `ls ./ | grep -e .webm -e .mp3` ]]; then
        ls ./ | grep -e .webm -e .mp3 | xargs rm; rm "`ls ./ | grep -e .webm -e .mp3`"
    fi
    exit
}

# Main
clear
trap trapsxoxo 2 20
syncActivity
while true; do
    read -p "command: " input
    clear
    case $input in
        exit)
            trapsxoxo
        ;;
        help*)
            help "${input#help}"
        ;;
        list|ls)
            list
        ;;
        remove*)
            song "remove" "$musicDir" "`echo ${input#remove} | xargs echo -n`"
        ;;
        load*)
            load "${input#load}"
        ;;
        play*)
            song "play" "$musicDir" "`echo ${input#play} | xargs echo -n`"
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
        *)
            syncActivity
            echo -e "[$(tput setaf 1)unknown command$(tput sgr0)]\ntry 'help'\n"
        ;;
    esac
done
