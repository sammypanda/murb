mp3dl="youtube-dl -x --audio-format mp3 -o '%(title)s.%(ext)s'";
help="help, $(tput bold)exit, list, remove, play [song/url], clean$(tput sgr0)"

while true
do
    read -p "input: " input
    clear
    case $input in
        exit)
            exit
        ;;
        help)
            echo $help
        ;;
        list|ls)
            if [[ `ls ./assets/music` == "" ]]
            then
                echo "$(tput setaf 1)song dir empty$(tput sgr0)"
            else
                ls ./assets/music
            fi
        ;;
        remove*)
            #remove from queueueeu
            intendedStr=${input#remove } # Remove 'remove ' from $input
            echo "intended: $intendedStr"
            correctedStr=`ls ./assets/music | grep -i -m1 "$intendedStr"` # i = case insensitive, m1 = only return one line   
            echo "search query: $correctedStr"
            echo "removed: $correctedStr"   
            rm ./assets/music/"$correctedStr"
        ;;
        play*)
            intendedStr=${input#play } # Remove 'song ' from $input
            $mp3dl "ytsearch:$intendedStr"
            mv *.mp3 ./assets/music
            clear
            if [[ $intendedStr == "" ]]
            then
                echo "song $(tput setaf 1)[name/url]$(tput sgr0)"
            else
                echo "$(tput bold)song stored: $(tput sgr0)$(tput setaf 4)`ls ./assets/music | grep -i "$intendedStr"`$(tput sgr0)"
            fi
            #add to queue
        ;;
        clean)
            rm * ./assets/music
            #clean current/queue
        ;;
        *)
            echo "$(tput setaf 1)unknown input$(tput sgr0)"
            echo "$(tput bold)$help$(tput sgr0)"
    esac
done