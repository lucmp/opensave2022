Warning: this project has been moved to https://sourceforge.net/projects/opensave2022/ as of April 29, 2023. Any updates should now be added there, probably not here anymore.

OPENSAVE2022

An Open/Save dialog for Tcl/Tk applications.

This is not a full and functional application. It's just a drop-in replacement for the default tk_getOpenFile and tk_getSaveFile open/save dialogs available in all Tcl/Tk stock installations. If you write Tcl/Tk applications, it may be useful to you. If you don't, then you probably don't need it.

How to install it:
================

1) Opensave2022 may or may not run on Windows. I'm sure that some parts won't. As of version 1.0 it has only been tested on Linux. If you use Windows, you should probably wait for a future version. Forget about Mac. I don't have a Mac machine and never will. But who knows, maybe someone will contribute a Mac version. Free software and all...

2) Download the zip file and unpack it. You will find one Tcl script, an "icons" directory and this README file. The "icons" directory is optional, Opensave2022 works without it, but it looks very ugly. Don't do that. Use the icons. Come on.

3) Run the Tcl script with Tcl/Tk, i.e. tclsh or wish. That will let you test it and see what Opensave2022 looks like and how it behaves so you can decide whether you like it or not.

4) Once you have run Opensave2022 for the first time, it will have created a configuration file at $XDG_CONFIG_HOME which usually means ~/.config/opensave2022. If you don't have the $XDG_CONFIG_HOME environment variable or the ~/.config directory, then the configuration file will be ~/.opensave2022rc. You may want to have a look at that configuration file. Editing it is tricky if you don't know anything about Tcl/Tk, but very easy if you do.

5) Opensave2022 is coded to use the Free Sans font by default. If you don't have it installed, I don't know what happens and what it will look like. You can always change the font in the configuration file and restart the application. That configuration file also keeps your bookmarks.

6) If you like what you see and want to use Opensave2022 in your own Tcl/Tk application, then open the Tcl script, delete the two lines after the last closing bracket "}" (they begin with "puts" and "exit") and leave just the opensave2022 proc. It's a large proc, more than 1,800 lines. Then all you have to do is to 'source' that file and call the opensave2022 proc instead of tk_getOpenFile and tk_getSaveFile. Just call 'opensave2022 open' or 'opensave2022 save' and everything else will be very predictable.


How to use it:
================

Opensave2022 is very keyboard-centric. The mouse works, but you can do everything in Opensave2022 without it. Here is the comprehensive list of all keyboard shortcuts:

a = alpha. It sorts the contents of the file list by file names in alphabetical order. It's the default mode when Opensave2022 is run for the first time, but whatever other choice you make will become the default for the next run. Your last choice always becomes the default. If you press 'a' again, the sorting order will be inverted, i.e. from z to a instead of a to z.

s = size. It sorts the contents of the file list by file size. If you press 's' again, the sorting order will be inverted.

d = date and time. It sorts the contents of the file list by last modification date and time. If you press 'd' again, the sorting order will be inverted.

p = permissions. It sorts the contents of the file list by the set of permissions. If you press 'p' again, the sorting order will be inverted.

o = owner. It sorts the contents of the file list by file ownership, in alphanumerical order. If you press 'o' again, the sorting order will be inverted.

c = copy path. It copies the currently selected path to the system clipboard. If you're highlighting any entry within the file list, the path of that file or directory will be copied. If you're hightlighting the first line, the one at the top, the path of the current directory, which contains the files and directories you see, will be copied.

h = toggle hidden. Opensave2022 hides "hidden" files by default. Press 'h' to make them visible and 'h' again to hide them. If they are toggled visible when you exit the application, then Opensave2022 will show hidden files by default in the next run. Remember, the last overall state of the entire application always becomes the default for the next session and will remain so until you change it.

b = add a bookmark. More on bookmarks later. Please keep reading.

t = toggles (hide/show) the top pane. I think a lot of people will like that pane and a lot of people will hate it. Well, just press "t" and move on with your life. I plan to do the same with the Bookmarks pane. I thought I had done it already, had to double-check the code and no, looks like I haven't. I will.

Alt + arrow up = go up. This key combination causes Opensave2022 to go up one level in the directory hierarchy, i.e. to go to the parent directory. Actually, all key shortcuts in Opensave2022 work with their own single letter or the Alt + letter combination. This one is an exception because the up arrow key alone won't work, you have to press Alt + up.

Left or right arrow = back and forth in navigation history. If you enter any directory, pressing the left arrow key (or Alt + left) will take you back to the directory you were viewing just before that. If you press the right arrow key (or Alt + right) you go back to the second directory. Every time you enter a new directory, you leave a "trail" of visited directories that you can follow back in reverse order whenever you want by repeatedly pressing the left arrow. If you do that enough times, you will land back on the first directory you viewed, and then you can visit all those directories again by repeatedly pressing the right arrow. Oh well, you get the picture.

Tab = navigate through panes. The first Tab press will land you on the Path Line. Another Tab will put the keyboard focus on the Bookmarks pane, and a third Tab press will land you back on the File List pane.

Path Line = that line contains the full path of the directory you're currently viewing. If you type any valid path there and press Enter, Opensave2022 will open that file or directory. If the path is not valid, nothing happens. Opensave2022 will just ignore it. I might add some kind of auto complete mechanism to that Path Line in a future version. Maybe.

The Path Line also works as a filter. For example, if you Tab to it and adjust the current /some/path to be /some/path/*txt (or *.txt, your call) Opensave2022 will only list file and directory names that end in "txt" (or ".txt"). Only "glob" mode is currently supported. I may add regex in the future, but don't count too much on it.

/ (forward slash) = jump to the Path Line. Tab does the same, but the forward slash means "search" or "filter" to a lot of Linux users, so why not.

Bookmarks
============

Whenever you have a file or folder highlighted and press the letter 'b' you are invited to create a bookmark to that file or directory. Bookmarks you add will be displayed in the leftmost pane. Just select one of them and press Enter (or click it with the mouse if you're one of those people) to open it instantly. You can bookmark files and directories. Whenever you add a bookmark, Opensave2022 will ask you if you want it to be a "Quickdial" entry. You answer "yes" by choosing a number from 1 to 0. Zero is in place of 10, so you can have up to 10 Quickdial entries. Obviously, that means that whenever you press the number in your keyboard corresponding to a previously stored Quickdial entry, Opensave2022 will open that file or directory faster than you can say "Tcl is a sparkling spectacle!" You can press the number keys either in the top row of the keyboard or in the numeric keypad. Because of course you can.

The excellent benefit of Quickdial entries only applies to red-blooded keyboard users. For mouse users, lesser creatures that they are, there is absolutely no difference between a Quickdial bookmark and an ordinary bookmark.

Whenever you select a bookmark in the Bookmarks pane, you can press the letter 'e' to edit the bookmark. You can then change its name, its path, its Quickdial number or delete it altogether. Yes, yes, you can also humiliate yourself by right-clicking the bookmark with your mouse and selecting an editing option...

I regret to inform that there is currently no fancy way to reorder ordinary bookmarks. Maybe in a future version. But Quickdial entries will always be displayed above the ordinary bookmarks. Quickdial bookmarks have VIP status. 


Known issues
============

This README file describes the very first public release of Opensave2022, occurred on the historical day of December 19, 2022. As of this release, Opensave2022 is obviously unfinished, obviously to anyone who tries to use it. Some things just don't work yet. Sorry. Please be patient. This is a hobby, I don't always have free time to work on it.

This alpha release of Opensave2022 only does the "open" part. The "save" part will come later. Sorry.

Opensave2022 currently only works properly on Linux. Windows will be supported in the near future. I will never support the Mac. Macs are super expensive, I don't own one and I can't even run it on a virtual machine. Hopefully, someone will be interested and contribute whatever changes may be necessary.

Opensave2022 takes a bit too long to display the contents of directories that contain a large number of files. In my machine, about 1,000 files or more. I thought about caching those directories so at least the delay is removed if you use the history navigation and visit that directory more than once. But the first visit will always be slow and the cache can only be good for the one running session because the directory can always be changed between sessions. So caching is not a good fix and it is a little complicated to implement. I may have to think the whole design over or find some other solution. Suggestions are very welcome.

The filtering mechanism in the Path Line is poor and feeble, easy to break. I'm aware of it. Everyone is encouraged to submit suggestions or bug reports.

I don't know the first thing about virtual file systems so they are not supported. Never say never, but don't count too much on it either unless someone else contributes code or gives me a very instructive lesson on the topic.

The entire body of the Opensave2022 parent widget is too wide. I'm sure that someone will complain about it. That is kind of sort of a design error on my part, but I happen to really like it what way. I have a large screen and I loathe small and crammed dialogs. In fact, I configure Openbox to open all of them in full screen mode and make them PANORAMIC. I am choosing a file, 100% of my focus is on that one dialog, why make it tiny and horribly uncomfortable like some stupid porthole? I don't live in a submarine. (Which suddenly makes me think that maybe yes, some Tclers may actually be deployed in submarines.)

If you have any issues, grievances or suggestions to share, I can be reached on the Github bug tracker or on comp.lang.tcl.

Old: https://github.com/lucmp/opensave2022
New: https://sourceforge.net/projects/opensave2022/



