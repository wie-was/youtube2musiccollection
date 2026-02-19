<img src="icons/logo/logo.png" alt="App-icon" width="400px"></img>

# youtube2musiccollection

Save Youtube videos as beautifully tagged audio files to your offline or online music collection.

## Usage

### Graphical User Interface
Simply run *youtube2musiccollection.sh*, or use the *youtube2musiccollection.desktop* file (exec paths need to be manually adapted first)
### CLI
Synopsis: `youtube2musiccollection.sh <YouTube‑URL> [options]`  
Run `youtube2musiccollection.sh --help` for more information

## Use cases
* Music preservation: Save music that you care about from the ever-changing, fast-paced world of the modern internet to the quiet and calm of your own music collection.
* Play audio files instead of videos to save bandwidth when on a metered network

## Description

This is a Bash script with a graphical user interface powered by [zenity](https://gitlab.gnome.org/GNOME/zenity). Providing at least one argument, such as `--help`, or the absence of zenity on the system, will start the program in command line mode.

youtube2musiccollection downloads and extracts the audio-track from any Youtube-video without format conversion, ie. without quality loss. The resulting audio-track will be encoded in either opus or aac/m4a, according to how the audio track was encoded by Youtube. The program further downloads the video-thumbnail as *cover.webp*, puts both files in a folder by the name of the video-title, edits the metatags of the audio file, moves the folder to a local directory or a remote sever via rsync.

### Tagging
The script tries to extract the meta-tags *artist* and *album* from the title of the Youtube-video, by splitting the title-string at a delimiter  "&nbsp;-&nbsp;"  or ":&nbsp;" (the spacing matters). This behaviour can be overruled by manually adding either *Artist*, *Album* or both in the respective dialog or as a command line option.

### Dependencies
Requires yt-dlp, ffmpeg, kid3-cli, jq, wget and rsync to be installed on the system. And requires zenity if you want to use the GUI.

## Installation
TBD

## Feedback
Bug reports, feature requests or feedback of any kind is very welcome!
