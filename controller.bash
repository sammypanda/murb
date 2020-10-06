# *) Globals
musicDir="./assets/music"

# Load) Globals
mp3dl="youtube-dl -x --audio-format mp3 -o '%(title)s.%(ext)s'"

# Help) Globals
help=("help" "exit" "list" "load" "remove" "start" "stop")
tip=("outputs this message, try 'help [option]'" "exits the controller and sync process" "shows the queued and the loaded songs" "parses songs from youtube, try 'load [song name]'" "removes loaded songs, try 'remove [song/all]'" "moves songs from the queue to the play-state" "stops streaming to murb")

# Dependencies
if ! [[ `pip3 show youtube-dl` ]]; then
    sudo apt-get install pip3
    pip3 install youtube-dl
    sudo apt-get install ffmpeg
fi

if ! [[ `dpkg -s jq` ]]; then
    sudo apt-get install jq
fi

# Functions
function remove() {
    directory=$1; file=$2
    targetFile=`ls $directory | grep -i -m1 "$file"` # Find a matching file to input
    if [[ $targetFile ]]; then
        read -p "Enter 'yes' to delete $(tput bold)$targetFile$(tput sgr0): " answer
        if [[ `echo $answer | tr [:upper:] [:lower:]` == "yes" ]]; then # Translates $answer to lowercase
            rm -v "$directory/$targetFile"
            echo -e "temp: [$(tput setaf 2)deleted$(tput sgr0)]\n"
        else
            echo -e "[$(tput setaf 1)cancelled$(tput sgr0)]\n"
        fi
    else
        echo -e "[$(tput setaf 1)unable to find song$(tput sgr0)]\n"
    fi
}

function list() {
    echo -e "$(tput bold)loaded:$(tput sgr0) \n`ls ./assets/music`\n"
    echo -e "$(tput bold)queued:$(tput sgr0) \n[jq command]\n"
}

function help() {
    option=$1
    option=`echo $option | tr [:upper:] [:lower:]` # Translates $option to lowercase
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
        $mp3dl "ytsearch:$query" # Temporarily store the song in the root
        file=`ls | grep ".mp3"` # Find the song
        if [[ $file ]]; then
            mv $file ./assets/music # Move to correct place
            echo -e "\n[stored $(tput setaf 4)$file$(tput sgr0)]\n"
            read -p "Enter 'yes' to queue $(tput bold)$file$(tput sgr0): " answer
            if [[ `echo $answer | tr [:upper:] [:lower:]` == "yes" ]]; then
                #queue $file
                echo -e "\n[queued $(tput setaf 4)$file$(tput sgr0)]\n"
            fi
        else
            echo -e "[$(tput setaf 1)cancelled$(tput sgr0)]\n"
        fi
    else
        echo -e "load $(tput setaf 1)[name/url]$(tput sgr0)\n"
    fi
}

# Main
clear
while true
do
    read -p "command: " input
    clear
    case $input in
        exit)
            exit
            #syncProcess "off"
        ;;
        help*)
            if [[ $input == "help" ]]; then
                help "$input"
            else
                help "${input#help}"
            fi
        ;;
        list|ls)
            list
        ;;
        remove*)
            remove "$musicDir" "${input#remove}"
        ;;
        load*)
            load "${input#load}"
        ;;
        *)
            echo -e "[$(tput setaf 1)unknown command$(tput sgr0)]\ntry 'help'\n"
        ;;
    esac
done
