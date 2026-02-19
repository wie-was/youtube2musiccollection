#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# youtube2musiccollection: Save Youtube videos as beautifully tagged audio files 
#    to your offline or online music collection.
#    Copyright (C) 2026 wie-was (volcanicash.grumbly603@passmail.net)
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
## Global user variables (➔USER CONFIG HERE)
#
# Set the destination location (rsync syntax).
destinationFolder=""
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 


# If no destination location is set manually, try to use the users "downloads" directory
if [ -z $destinationFolder ]
then
    if [ -d $HOME/Downloads ]
    then
        destinationFolder=$HOME/Downloads
    elif [ -d $HOME/downloads ]
    then
        destinationFolder=$HOME/downloads
    else
        destinationFolder=$HOME
    fi
fi

## Functions definitions

# Function to display repeated characters (for display purposes mostly)
function repeatCharacter()
{
    for ((character=1; character<=$2; character++))
    do 
        echo -n "$1"
    done
}

# Function to output progress percentage only in GUI mode
function zenityProgressPercentageOutput() {
    if [[ $GUIMode == "on" ]]
    then
        echo $1
    fi
}

# Function to display arrays. $1 refers to the array-name-string, $2 to the concatenator used to combine the last two elements of the array
function displayArrays() {
    for ((i=0; i<$(eval echo "\${#$1[@]}"); i++))
    do 
        if [ $i -eq $(( $(eval echo "\${#$1[@]}") - 1 )) ]
        then 
            echo -n "$(eval echo "\${$1[$i]}")"
        elif [ $i -eq $(( $(eval echo "\${#$1[@]}") - 2 )) ]
        then
            echo -n "$(eval echo "\${$1[$i]}") $2 "
        else 
            echo -n "$(eval echo "\${$1[$i]}"), "
        fi 
    done
}

## Global program variables

# Set the name of the program
name="youtube2musiccollection"
nameGUI=$name
# Set the version
version=0.5
# Author
author="wie-was"
# Email
email="volcanicash.grumbly603@passmail.net"
# Github
github="https://github.com/wie-was/youtube2musiccollection"
# Date
year="2026"
# Logo
logo="$(dirname $0)/icons/logo/logo.png"
# Dependencies list
dependencies=(yt-dlp ffmpeg kid3-cli jq wget rsync)
# Supported audio codecs
supportedAudioCodecs=("opus" "aac/m4a")
# Set the temporary download folder
downloadFolder=/tmp
# Script path (for restarting the script with `exec`)
pathToScript=$(readlink -f "$0")

## GUI
# GUI window width
windowWidth=300
# "Setup" button text
buttonLabelSetup="Settings ⚙"
# "About" button text
buttonLabelAbout="About 🛈"
# "License" button text
buttonLabelLicense="License ©"

# Comment / Abstract
abstract="Save Youtube videos as beautifully tagged audio files to your offline or online music collection."
# Description
description="<b>Description</b>

This is a Bash script with a graphical user interface powered by zenity. \
Providing at least one argument, \
such as <tt>--help</tt>, will start the program in command line mode.

<i>$nameGUI</i> downloads and extracts the audio-track from any Youtube-video without format conversion, \
ie. without quality loss. The resulting audio-track will be in the format of either opus or aac/m4a, according to how it was encoded by Youtube in the first place. \
The program further downloads the video-thumbnail as <i>cover.webp</i>, puts both files in a folder by the name of the video-title, \
edits the metatags of the audio file and finally moves the folder to a local or remote directory via rsync (SSH public key authentication)."

# Help text
helpText="$(repeatCharacter "# " 22)\n# Welcome to $name! 💿  #\n$(repeatCharacter "# " 22)\n
Synopsis: $name <YouTube‑URL> [options]\t (→ CLI mode)\n\t  $name \t\t\t\t (→ GUI mode) \n\n\
$description\n\n\
Dependencies: $(IFS=' '; echo -n ${dependencies[@]}) \n\n\
Arguments: \n\n\
--artist=\"Artist Name\"
--album=\"Album Name\"
--no-transfer (→ Keeps the files in the temporary download folder ($downloadFolder) on the local machine)
--destination=\"Destination directory\" (→ local or remote directory (rsync-syntax))
--help: Display this help text
--version: Display version info\n
Example usage:\n
./$name https://www.youtube.com/watch?v=Q__0zE0URbg
./$name https://www.youtube.com/watch?v=sCYzXDYN_vk --artist=\"Radiohead\" --album=\"The King of Limbs (Live From The Basement)\" --no-transfer\n\n
License: \n\n\
This program comes with ABSOLUTELY NO WARRANTY; for details read LICENSE.md. \
This is free software, and you are welcome to redistribute it \
under certain conditions; read LICENSE.md for details."
# Zenity GUI About page
zenityIntroText="<big><b>$nameGUI</b></big>

$abstract

$description

<span weight='bold'>Requires $(displayArrays dependencies and)</span> to be installed on the system. And requires <b>zenity</b>, if you want to use the GUI.

𝆺 The script tries to extract the meta-tags \<i\>Artist\</i\> and \<i\>Album\</i\> from the title of the Youtube-video, by splitting the title-string \
at a delimiter \" - \" or \": \" (the spacing matters). This behaviour can be overruled by manually adding either <i>Artist</i>, <i>Album</i> or both.
𝆺 \<i\>Destination\</i\> sets a one-time destination folder, overriding the destination location defined in the Settings.


<b>Credits</b>

Copyright © $year $author. Get in touch or contribute:\n\n<u>$github</u>

<small>This program comes with ABSOLUTELY NO WARRANTY; for details press $buttonLabelLicense.
This is free software, and you are welcome to redistribute it
under certain conditions; press $buttonLabelLicense for details.</small>
"

## Error texts both CLI and zenity GUI
errorTextNetwork="yt-dlp was not able to download the required data from Youtube. Quit VPNs, check your network connection, check the provided URL and try again."
errorTextDownload="Download of the audio-file with yt-dlp failed."
function errorTextMissingDependencies() {
    echo "The following software seems to be missing on your system:\n\n$(displayArrays missingDependencies and)\n\nPlease install, make sure the commands are available in \$PATH, and try again"
}

## Error texts CLI
errorText="\n$name: Invalid arguments. \nUsage: $name <YouTube‑URL> [arguments], or type $name --help for more info."
# Unknown error
errorTextUnknown="Unknown error, exiting program."



# Set the exit messages
function exitMessage() {
    echo "Now check your music collection @ <tt>$destinationFolder</tt> for new music!"
}

exitMessageNoTransfer="$name: Files downloaded and stored on your computer in $downloadFolder"

# # #
## Start of the program
# # #

## Check for dependencies and store missing dependencies in an array for later display

for dependency in ${dependencies[@]}
do
    which $dependency > /dev/null 2>&1
    if [ $? -ne 0 ]
    then
        missingDependencies+=($dependency)
    fi
done

# Additionally, check if zenity is available. If not, start CLI mode
    which zenity > /dev/null 2>&1
    if [ $? -ne 0 ]
    then 
        zenityAvailable="false"
    fi

## If no arguments are provided, use the zenity GUI mode

if [ $# -eq 0 ] && [[ $zenityAvailable != "false" ]]
then
    GUIMode=on
    # Display error and exit if dependencies are missing
    if [[ ! -z "${missingDependencies[@]}" ]]
    then
        zenity --error \
        --title="Missing Dependencies" \
        --text="$(errorTextMissingDependencies)" \
        --no-wrap
        exit 1
    fi

    # Spawn the welcome window and harvest the user input into a variable

    zenityOutput=$(zenity --entry \
    --width=$windowWidth \
    --title="$nameGUI" \
    --text="Enter a Youtube-URL and press ⮠" \
    --ok-label="OK ⮠" \
    --extra-button="$buttonLabelSetup" \
    --extra-button="$buttonLabelAbout")

    # Dev mode: Insert a URL by defaul: --entry-text="https://www.youtube.com/watch?v=yCgZmGwx9VU" \

    # Check the exit status. If "Cancel" has been pressed (ie. the exit status not equals 0 AND there is no zenity-output), exit the program immediately
    if [ $? -ne 0 ] && [[ -z $zenityOutput ]]
    then
        exit 1
    # If "About" has been pressed, the exit status must be 1, and the value returned from zenity must equal the exact text of the button
    elif [ $? -ne 0 ] && [[ $zenityOutput == "$buttonLabelAbout" ]]
    then
        # About page loop (required because of the License "sub-menu" and the need to go back to the About page instead of the "Home" page)
        while true
        do
            # Spawn the About page in GUI mode
            zenity --info \
            --title="$buttonLabelAbout" \
            --text="$zenityIntroText" \
            --icon="$logo" \
            --width=600 \
            --ok-label="🢦 Back to Main Menu" \
            --extra-button="$buttonLabelLicense"
            # Spawn the License page
            if [ $? -ne 0 ]
            then
                zenity --text-info \
                --title="$buttonLabelLicense" \
                --filename="$(dirname $0)/LICENSE.md"
            else
                break
            fi

        done

        # Restart program (aka go back to main menu)
        exec "$pathToScript"
    # If "Setup" has been pressed, the exit status must be 1, and the value returned from zenity must equal the exact text of the button
    elif [ $? -ne 0 ] && [[ $zenityOutput ==  $buttonLabelSetup ]]
    then
        zenity --info \
        --title="$buttonLabelSetup" \
        --text="Settings not implemented yet...come back soon! In the meantime: Permanently change the destination location in the file <tt>$0</tt> Search for \"USER CONFIG\".\n\nCurrently hardcoded <b>destination location</b>: <tt>$destinationFolder</tt>" \
        --icon="$logo" \
        --ok-label="OK"
        # OK Label: "Save Settings 🖫"
        # TODO: Rsync DRY-RUN to check if the destination directory exists and is valid (we *don't* want to create it if it doesn't exist)

        # Restart program (aka go back to main menu)
        exec "$pathToScript"

    # Else "OK" must have been pressed, so let's check the user input next
    else
        # If no input is provided at all, display hint and exit
        if [[ -z $zenityOutput ]]
        then
            zenity --error \
            --title="No URL provided" \
            --width="$windowWidth" \
            --text="Enter a Youtube-URL, eg. \n\n<i>https://www.youtube.com/watch?v=sCYzXDYN_vk</i>\n\nand try again" \
            --no-wrap
            #--ellipsize            
            # Restart program (aka go back to main menu)
            exec "$pathToScript"
        fi
        # Check the validity of the provided Youtube-URL
        if [[ $zenityOutput =~ .*youtube\.com/watch\?v=.* ]] || [[ $zenityOutput =~ .*youtu\.be/.* ]]
        then
            # Assign the url variable
            url=$zenityOutput
            # fetch metadata and spawn form
            fetchParseDisplayMetadata

        else
            zenity --error \
            --title="URL not valid" \
            --text="The provided URL does not seem to be a valid Youtube-URL" \
            --no-wrap
            # Restart program (aka go back to main menu)
            exec "$pathToScript"
        fi
    fi

## Else (if CLI arguments were provided OR zenity is not available,) assess the arguments

else
    GUIMode=off
    # Display error and exit if dependencies are missing
    if [[ ! -z "${missingDependencies[@]}" ]]
    then
        echo -e "\n$name: $(errorTextMissingDependencies)"
        exit 1
    fi

    for argument in "$@"
    do
        case $argument in
            *youtube.com*) url=$(echo $argument);;
            --artist*) artist=$(echo $argument | /usr/bin/grep -oP '(?<=\=).*');;
            --album*) album=$(echo $argument | /usr/bin/grep -oP '(?<=\=).*');;
            --no-transfer*) noTransfer=1;;
            --destination*) destination=$(echo $argument | /usr/bin/grep -oP '(?<=\=).*');;
            --help) echo -e "$helpText"; exit;;
            --version) echo -e "$name, version $version \nAuthor: $author, $year"; exit;;
            *) echo -e $errorText; exit
        esac
    done
fi

## Wrapping parts of the script into functions, to "feed" the zenity progress bar

fetchParseDisplayMetadata() {
    ## Grab metadata with yt-dlp and parse them with jq

    # First, only grab the JSON metadata with yt‑dlp (required to create a folder and display metadata)
    metadata=$(/usr/bin/yt-dlp --skip-download --print-json --no-warnings --socket-timeout 5.5 "$url" 2>&1)

    # Error handling yt-dlp
    if [ $? -ne 0 ]
    then
        if [[ $GUIMode == "on" ]]
        then
            zenity --error \
            --title="Something went wrong" \
            --width="$windowWidth" \
            --text="$errorTextNetwork\n\nyt-dlp reports:\n\n<tt>$metadata</tt>"
            # Restart program (aka go back to main menu)
            exec "$pathToScript"
        else
            echo -e "$errorTextNetwork\n\nyt-dlp reports:\n\n$metadata"
            exit 1
        fi
    fi

    # Pull the fields you need with jq
    title=$(echo "$metadata" | jq -r '.fulltitle // .title // empty')
    date=$(echo "$metadata" | jq -r '.release_date // .upload_date // empty')
    container=$(echo "$metadata" | jq -r '.ext')
    acodec=$(echo "$metadata" | jq -r '.acodec')
    comment=$(echo "$metadata" | jq -r '.description // empty')
    youtubeUrl=$(echo "$metadata" | jq -r '.webpage_url')
    thumbnailUrl=$(echo "$metadata" | jq -r '.thumbnail')

    ## Extract artist name and album name from title, only if $artist and $album strings are empty (zero). Only works with " - " delimiter currently

    # Function to check the $title string for delimiters
    delimiterSearch()
    {
        # Check for " - "
        if [[ $title =~ .*\ -\ .* ]];
        then
            delimiter=" - "
        # Check for ": "
        elif [[ $title =~ .*:\ .* ]];
        then
            delimiter=": "
        fi
    }
    # Check the $title string for delimiters
    delimiterSearch
    if [ -z $artist ]
    then
        # See Shell Parameter Expansion (Manual 3.5.3), "pattern removal"
        artist=${title%$delimiter*}
    fi
    # Check the $title string for delimiters
    delimiterSearch
    if [ -z $album ]
    then
        # See Shell Parameter Expansion (Manual 3.5.3), "pattern removal"
        album=${title#*$delimiter}
    fi

    ## Further processing

    # Format date
    date=$(date -d $date +'%Y-%m-%d')

    # Add the source video-URL to the comment section
    comment=$(echo -e "$comment\n\nVideo version: $youtubeUrl")

    ## Escaping: We need to escape various strings for various purposes

    # Remove forward slashes from $title for file and folder creation
    fileFolderTitle="${title//\//}"
    # Remove leading dots from $title for file and folder creation
    fileFolderTitle="${title/#./}"

    # Escape single-quotes and double-quotes in the strings $title, $comment, $artist, $album.
    # Required for the later tagging process. See Shell Parameter Expansion (Manual 3.5.3)
    # Omitted for now

    # Escape single-quotes for displaying the metadata in zenity
    #title=${title//"'"/"\'"}
    commentDisplayZenity=${comment//"'"/"\'"}
    #artist=${artist//"'"/"\'"}
    #album=${album//"'"/"\'"}

    # Escape double-quotes
    #title=${title//'"'/'\"'}
    commentDisplayZenity=${commentDisplayZenity//'"'/'\"'}
    #artist=${artist//'"'/'\"'}
    #album=${album//'"'/'\"'}

    # Escape Ampersand
    commentDisplayZenity=${commentDisplayZenity//'&'/'&amp;'}
    artistDisplayZenity=${artist//'&'/'&amp;'}
    albumDisplayZenity=${album//'&'/'&amp;'}
    titleDisplayZenity=${title//'&'/'&amp;'}

    ## Create a new folder for the files to be downloaded in

    cd $downloadFolder
    # If the specified download folder does not exist, use the users home folder
    if [ $? -ne 0 ]
    then
        cd $HOME
    fi
    # Don't invoke mkdir if the folder already exists (from previously downloading the same video, for example)
    if [[ ! -d $fileFolderTitle ]]
    then
        mkdir "$fileFolderTitle"
    fi
    cd "$fileFolderTitle"

    ## Show what we captured and processed, for debugging purposes

    printf 'Title        : %s\n' "$title"
    printf 'Artist       : %s\n' "$artist"
    printf 'Album        : %s\n' "$album"
    printf 'Date         : %s\n' "$date"
    printf 'YouTube URL  : %s\n' "$youtubeUrl"
    printf 'Thumbnail URL: %s\n' "$thumbnailUrl"
    printf 'container    : %s\n' "$container"
    printf 'acodec       : %s\n' "$acodec"
    printf 'Folder Title : %s\n' "$fileFolderTitle"
    printf 'Comment      : %s\n' "$comment"

    # Output for the zenity-progress-bar (fetchParseDisplayMetadata)
    zenityProgressPercentageOutput 100

    ## Zenity-dialog for accepting or rejecting the automatic tagging
    if [[ $GUIMode == "on" ]]
    then
        # Spawn the info box / welcome popup, to be seen before the form
        zenityDecision=$(zenity --question \
        --width=$windowWidth \
        --title="Preview of metadata and destination location" \
        --text="<b>Artist</b> \t\t$artistDisplayZenity\n<b>Album</b> \t\t$albumDisplayZenity\n<b>Title</b> \t\t$titleDisplayZenity\n<b>Date</b> \t\t$date\n<b>Codec</b> \t\t$acodec\n<b>Comment</b>\t$commentDisplayZenity\n\n<b>Destination</b>\t$destinationFolder" \
        --ok-label="🆗 Computer" \
        --cancel-label="Manually set Metadata or Destination location" \
        --no-wrap)

        # FEATURE: Add back the "Folder display to the --text string above, like so: \n<b>Folder</b> \t$fileFolderTitle"

        # If "OK" has been pressed, do nothing and continue
        if [ $? -eq 0 ]
        then
            true
        # Else spawn an input form
        else
            # Create the form GUI and harvest input into an array
            zenityFormOutput=$(zenity --forms \
            --title="Manually set Metadata or Destination location" \
            --text="<span weight='light' bgcolor='white'>Only adjust the fields that need adjustment\n\nUse <tt>rsync</tt>-syntax for <i>Destination location</i>, for example\n<tt><span color='darkgrey'>music.server.net:/path/to/music/library/</span></tt> (remote) or\n<tt><span color='darkgrey'>/path/to/music/library/</span></tt> (local)</span>" \
            --icon="$logo" \
            --width="600" \
            --add-entry="Artist" \
            --add-entry="Album" \
            --add-calendar="Date" \
            --forms-date-format=%Y-%m-%d \
            --add-entry="Destination location")

            # Check the exit status. If "Cancel" has been pressed (ie. the exit status not equals 0), exit the program immediately
            if [ $? -ne 0 ]
            then
                # Restart program (aka go back to main menu)
                exec "$pathToScript"
            else
                zenity --info --text="$zenityFormOutput"
                # Harvest the user-input into an array
                IFS='|' read -ra zenityArguments <<< $zenityFormOutput               
                # Extract and validate data from the array

                zenity --info --text="$(echo ${zenityArguments[@]}, ${zenityArguments[0]}, ${zenityArguments[1]})"
                
                # Only override $artist and $album if the user has entered something
                if [ -n "${zenityArguments[0]}" ]
                then
                    artist=${zenityArguments[0]}
                    zenity --info --text="$artist"
                fi
                if [ -n "${zenityArguments[1]}" ]
                then
                    album=${zenityArguments[1]}
                fi
                # Only override $date when it's not today's date. This is a limitation in zenity: There is always output of the calendar form.
                # In other words: Setting the current day as a date is not possible.
                if [ -n ${zenityArguments[2]} ] && [ ${zenityArguments[2]} != $(date +%Y-%m-%d) ]
                then
                    date=${zenityArguments[2]}
                fi
                destination=${zenityArguments[3]}
            fi

        fi    
    # Do nothing in CLI mode, because it is non-interactive
    else
        sleep 0
    fi
}

writeMoveData() {

    zenity --info --text="$artist, $album, $date, $destination"

    ## Determine the audio codec

    if [[ $container == "mp4" ]]
    then
        acodec="m4a"
    elif [[ $acodec == "opus" ]]
    then
        acodec=$acodec
    else
        # If the audio codec is not one of the above, display error and exit
        # GUI version
        if [[ $GUIMode == "on" ]]
        then
            displayCodecNow=$(displayArrays supportedAudioCodecs or)
            zenity --error \
            --title="Unknown audio codec" \
            --width="$windowWidth" \
            --text="The codec of the audio stream of \"$youtubeUrl\" is not $displayCodecNow. Please inspect manually." \
            --no-wrap
            exit
        # CLI version
        else
            echo "$name: Unknown audio codec: Please inspect manually. Aborting process"
            exit
        fi
    fi

    # Output for the zenity-progress-bar
    zenityProgressPercentageOutput 15

    ## Download and process the audio file and the video-thumbnail

    # Download video-container-file, most likely .webm, containing only the audiostream.
    /usr/bin/yt-dlp -f bestaudio --no-playlist -o "$fileFolderTitle.$container" "$url" --progress
    # Check if the file has been written
    if [ ! -f "$fileFolderTitle.$container" ]
    then
        if [[ $GUIMode == "on" ]]
        then
            zenity --error \
            --title="Something went wrong" \
            --width="$windowWidth" \
            --text="$errorTextDownload"
            # Restart program (aka go back to main menu)
            exec "$pathToScript"
        else
            echo "$name: $errorTextDownload Exiting program."
            exit
        fi
    fi

    # Error handling yt-dlp
    if [ $? -ne 0 ]
    then
        if [[ $GUIMode == "on" ]]
        then
            zenity --error \
            --title="Something went wrong" \
            --width="$windowWidth" \
            --text="$errorTextNetwork\n\nyt-dlp reports:\n\n<tt>$metadata</tt>"
            # Restart program (aka go back to main menu)
            exec "$pathToScript"
        else
            echo -e "$errorTextNetwork\n\nyt-dlp reports:\n\n$metadata"
            exit 1
        fi
    fi

    # Output for the zenity-progress-bar
    zenityProgressPercentageOutput 60

    # Losslessly extract the audiostream from the container to an actual audio-file (opus for webm, or aac (m4a) for mp4).
    # -y option to automatically overwrite a potenially existing file
    /usr/bin/ffmpeg -hide_banner -i "$fileFolderTitle.$container" -vn -codec:a copy -y "$fileFolderTitle.$acodec"
    # Download the thumbnail (webp hardcoded)
    /usr/bin/wget -O cover.webp $thumbnailUrl
    # Delete the video file
    /usr/bin/rm "$fileFolderTitle.$container"

    # Output for the zenity-progress-bar
    zenityProgressPercentageOutput 80

    ## Edit the metatags of the file

    #echo "$fileFolderTitle.$acodec"
    /usr/bin/kid3-cli -c "set artist '$artist'" -c "set album '$album'" -c "set title '$title'" -c "set tracknumber '1'" -c "set comment '$comment'" -c "set date '$date'" "$fileFolderTitle.$acodec"

    # Output for the zenity-progress-bar
    zenityProgressPercentageOutput 90

    ## Move the folder to the music collection folder, except if the --no-transfer argument is set
    if [[ -z $noTransfer ]]
    then
        cd ..
        # If /tmp is set as destination, then simply leave the files where they are and proceed to the exit messages
        if [[ $destination =~ ^/tmp/? ]]
        then
            # Required for the exit message
            destinationFolder=$destination
        else
            # If destination has been manually set (and it is not /tmp), use this instead of the hardcoded destination
            if [[ ! -z $destination ]]
            then
                # Rsync DRY-RUN to check if the destination directory exists (we *don't* want to create it if it doesn't exist)
                rsyncOutput=$(/usr/bin/rsync -avP --dry-run "$fileFolderTitle" "$destination")
                # If the Output contains "created directory", then that's not good
                if [[ $rsyncOutput =~ .*"created directory".* ]]
                then
                    # zenity GUI version
                    if [[ $GUIMode == "on" ]]
                    then
                        zenity --error \
                        --title="Transfer failed" \
                        --text="The transfer to the destination directory <tt>$destination</tt> failed.\nIt seems that the destination directory does not exist." \
                        --width="$windowWidth" 
                        exit 1
                    # CLI version
                    else
                        echo -e "The transfer to the destination directory $destination failed.\nIt seems that the destination directory does not exist."
                        exit 1
                    fi
                # Else the destination folder exists and is valid, so we can proceed
                else
                    destinationFolder=$destination
                fi
            fi
            /usr/bin/rsync -avP --remove-source-files "$fileFolderTitle" "$destinationFolder"
            # Error message if the transfer failed, eg. because the destination is not available (wrong server address for example)
            # Note that this can be the case because of a wrong temporary address, or a wrong config-address or a server that's not available etc. etc.
            if [ $? -ne 0 ]
            then
                # zenity GUI version
                if [[ $GUIMode == "on" ]]
                then
                    zenity --error \
                    --title="Transfer failed" \
                    --text="The transfer to the destination directory <tt>$destinationFolder</tt> failed.\nPlease check if the destination is available." \
                    --width="$windowWidth"
                    exit 1
                # CLI version
                else
                    echo -e "The transfer to the destination directory $destinationFolder failed.\nPlease check if the destination is available."
                    exit 1
                fi
            fi
            /usr/bin/rm -r "$fileFolderTitle"
        fi

        ## Exit messages

        # zenity GUI version
        if [[ $GUIMode == "on" ]]
        then
            # Output for the zenity-progress-bar
            zenityProgressPercentageOutput 100
            exitMessageGUINow=$(exitMessage)
            zenity --info \
            --title="" \
            --text="$exitMessageGUINow" \
            --width="$windowWidth" \
            --extra-button="Open Destination folder"
            # If extra button has been clicked
            if [ $? -ne 0 ]
            then
                xdg-open $destinationFolder
            fi
        # CLI version
        else
            echo -e $name: $(exitMessage)
        fi
    # Exit message (--no-transfer flag set. CLI mode only)
    else
        echo -e $exitMessageNoTransfer
    fi
}

# Spawn progress bars (only if in GUI mode)
if [[ $GUIMode == "on" ]]
then
    # Fake call just for the sake of having a nice progress bar :D
    /usr/bin/yt-dlp --skip-download --print-json --no-warnings --socket-timeout 5.5 "$url" 2>&1 | zenity --progress \
    --width="$windowWidth" \
    --title="Fetching metadata" \
    --text="This may take a few of seconds..." \
    --pulsate \
    --auto-close \
    --no-cancel &
    fetchParseDisplayMetadata
    
    writeMoveData | zenity --progress \
    --width="$windowWidth" \
    --title="Fetching and processing data" \
    --text="This may take a few of seconds..." \
    --percentage=5 \
    --auto-close \
    --no-cancel \
    --time-remaining

else
    fetchParseDisplayMetadata
    writeMoveData
fi

## FINE. That's all folks!