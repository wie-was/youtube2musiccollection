![](icons/logo/logo.png)

# youtube2musiccollection

Save Youtube videos as beautifully tagged audio files to your offline or online music collection.

## Use cases
* Preserve music that you care about to your music collection. We have all experienced Youtube vidoes being taken down
* Play audio files instead of videos to save bandwidth when on a metered network

## Description
youtube2musiccollection downloads and extracts the audio-track from any Youtube-video without format conversion, ie. without quality loss. The resulting audio-track will be encoded in either opus or aac/m4a, according to how the audio track was encoded by Youtube. The program further downloads the video-thumbnail as *cover.webp*, puts both files in a folder by the name of the video-title, edits the metatags of the audio file, moves the folder to a local directory or a remote sever via rsync.

### Tagging
The script tries to extract the meta-tags *artist* and *album* from the title of the Youtube-video, by splitting the title-string at a delimiter  "&nbsp;-&nbsp;"  or ":&nbsp;" (the spacing matters). This behaviour can be overruled by manually adding either *Artist*, *Album* or both in the respective dialog.

## Technical description
This is a Bash script with a graphical user interface powered by [zenity](https://gitlab.gnome.org/GNOME/zenity). Providing at least one argument, such as `--help`, will start the program in command line mode.

### Dependencies
Requires yt-dlp, ffmpeg, kid3-cli, jq, wget and rsync to be installed on the system.

## Installation
Bli blah.

### Usage instructions

#### Setup
The Setup dialog currently allows you to permanently change the destination folder.

## Feature requests
I'm happy to receive ideas about what feature to implement next.
