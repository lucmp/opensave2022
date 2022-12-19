#!/usr/bin/env tclsh

# Version 1.0, November 2022.
# Copyright © 2022 by Luciano Espirito Santo.
# Permission to use, copy, modify, and/or distribute this software for 
# any purpose with or without fee is hereby granted.
# 
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL 
# WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED 
# WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE 
# AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL 
# DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA 
# OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER 
# TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR 
# PERFORMANCE OF THIS SOFTWARE.
# 
# TL;DR: BSD Zero Clause License
# 
# Hawcons icon pack by Yannick Lung
# https://www.iconfinder.com/iconsets/hawcons

namespace eval ::opensave					{}
namespace eval ::opensave::cfg				{}
namespace eval ::opensave::cfg::manage		{}
namespace eval ::opensave::cfg::existing	{}

proc ::opensave::opensave2022	{argAction}	{
	
	set ::opensave::argAction $argAction

	proc ::opensave::p.FirstVars {}	{


		set ::opensave::cfg::homedir			[file dirname [file normalize [info script]]]
		set ::opensave::cfg::debug				1

		#if {[file exists $env(XDG_CONFIG_HOME)] && [file isdirectory $env(XDG_CONFIG_HOME)]}	{puts found}

		set ::opensave::CONFIGDIR				[file normalize $::env(HOME)/.opensave2022]
		set ::opensave::CONFIGFILE				[file normalize $::env(HOME)/.opensave2022rc]
		# WARNING: $::env(HOME) works fine in Linux. I don't know what happens
		# in any of the versions of Windows, Mac or BSD.
		# (BTW, does Tcl/Tk run on some other platform?)
		# Check that out if you implement this in anything other than Linux.

		set ::opensave::CURRENTDIR				[file dirname [file normalize [info script]]]
		# WARNING: You may want to change the line above. Just make sure that
		# the ::opensave::CURRENTDIR variable exists and is not empty.
		# The open/save dialog will display that directory first when it runs.

		set ::opensave::HISTORYBACK				{}
		set ::opensave::HISTORYFWD				{}
		array set ::opensave::CACHE				{}
		# WARNING: These variables must exist and be empty.
		
		set ::opensave::COLUMNS				[list FileList Size Date Permission Owner]
		
		catch {unset ::opensave::OUTPUT}
	}

	proc ::opensave::p.config {}	{
		array set ::opensave::cfg::settings	{
		HeaderBg			#23ADB5
		HeaderFg			#000000
		HeaderFont			{"Free Sans" 20 bold}
		HiddenFiles			"hide"
		IconSize			24
		InputBg				#ffffff
		InputFg				#000000
		InputFont			{"Free Sans" 10 bold}
		LabelBg				#c0c0c0
		LabelFg				#000000
		LabelFont			{"Free Sans" 9}
		TopPane				"show"
		SortedColumnBg		#F2F2F2
		SortedColumnFg		#000000
		Sorting1			"alpha"
		Sorting2			"increase"
		StatusBg			#c0c0c0
		StatusFg			#000000
		StatusFont			{"Free Sans" 12}
		TextBg				#ffffff
		TextFg				#000000
		TextFont			{"Free Sans" 14}
		}

		if {[file exists $::opensave::CONFIGFILE]}	{
			set _rexp {^\s*([^= ]+)\s*=\s*([^=]+)}
			set _fp [open $::opensave::CONFIGFILE r]
			while 	{-1 != [gets $_fp _line]}	{ 
					if {$_line == ""}  				{continue}
					if {[regexp {^#.*} $_line]}  	{continue}
					if {![regexp $_rexp $_line]}	{continue}
					regexp $_rexp $_line -> k v
					set ::opensave::cfg::settings($k) $v
			}
			close $_fp
		}

		foreach  {k v}  [array get ::opensave::cfg::settings]  	{
			set [join "::opensave::cfg:: $k" ""] $v
		}

		if {! [file exists $::opensave::CONFIGFILE] || ! [file isfile $::opensave::CONFIGFILE]}	{
			set _fp [open $::opensave::CONFIGFILE w]
			foreach _item [lsort [array names ::opensave::cfg::settings]]	{
				puts $_fp "$_item = $::opensave::cfg::settings($_item)"
			}
			close $_fp
		}
	}

	proc ::opensave::p.FormatUnits  {value}  	{
		set len [string length $value]
		if 	{$value == 0}  		{return 0}
		if 	{$value < 1024}  	{return "$value B"}
		if 	{$value >= 1024}  	{
			set unit [expr {($len - 1)/3}]
			return [format "%.1f %s" [expr {$value/pow(1024,$unit)}] [lindex \
				[list B KB MB GB TB PB EB ZB YB] $unit]]
		}
	}

	proc ::opensave::p.Deoctalize {Octal}	{
		set Octal [string reverse [string range [string reverse $Octal] 0 2]]
		# Sheesh. We should be able to use negative values with string range.
		set Deoctal [string map {\
			"7" "rwx" "6" "rw-" "5" "r-x" "4" "r--" \
			"3" "-wx" "2" "-w-" "1" "--x" "0" "---"} $Octal]
		return $Deoctal
	}

	proc ::opensave::p.LockAllColumns {}	{
		foreach fe $::opensave::COLUMNS	{
			[set [join [list ::opensave:: $fe Column] ""]] configure -state disabled
		}
		$::opensave::bookmarks configure -state disabled
	}

	proc ::opensave::p.ClearAllColumns {}	{
		foreach fe $::opensave::COLUMNS	{
			[set [join [list ::opensave:: $fe Column] ""]] configure -state normal
			[set [join [list ::opensave:: $fe Column] ""]] delete 1.0 end
		}
	}

	proc ::opensave::p.InsertCorrectIcon {widget target}	{
		set iconsize $::opensave::cfg::IconSize
		set iconsdir "$::opensave::cfg::homedir/icons/defaultset/[file join ${iconsize}pixels]"
			puts $iconsdir/updir_icon.png
		if {$target == "___!UPDIR_ICON!___"}	{
			$widget insert end [subst -nocommands "\\u2BA5"]
			return
			# "\\u2934"
			# "\\u2B8D"
			# "\\u2B61"
			# "\\u21E7"
			# "\\uE696"
			# "\\uE68E"
			if {[file exists $iconsdir/updir_icon.png]}	{
				$widget image create end -image [image create photo -file $iconsdir/updir_icon.png]
			} else {$widget insert end "^"}
			return
		}
		if {$target == "___!BLANK_FILE_ICON!___"}	{
			if {[file exists $iconsdir/file_icon_blank.png]}	{
				$widget image create end -image [image create photo -file $iconsdir/file_icon_blank.png]
			} else {$widget insert end ""}
			return
		}
		if {$target == "___!BLANK_DIR_ICON!___"}	{
			if {[file exists $iconsdir/dir_icon_blank.png]}	{
				$widget image create end -image [image create photo -file $iconsdir/dir_icon_blank.png]
			} else {$widget insert end ""}
			return
		}
		if {$target == "___!ADD_BOOKMARK_NOSELECT!___"}	{
			#$widget insert end [subst -nocommands "\\uf09d"] e5a5
			#return
			if {[file exists $::opensave::cfg::homedir/icons/others/ZoomIn.png]}	{
				$widget image create end -image [image create photo -file $::opensave::cfg::homedir/icons/others/ZoomIn.png]
			} else {$widget insert end "+"}
			return
		}
		if {$target == "___!ADD_BOOKMARK_SELECT!___"}	{
			if {[file exists $::opensave::cfg::homedir/icons/others/ZoomIn.png]}	{
				$widget image create end -image [image create photo -file $::opensave::cfg::homedir/icons/others/ZoomIn_select.png]
			} else {$widget insert end "+"}
			return
		}
		if {[file type $target] == "file"}		{
			if {[file exists $iconsdir/file_icon.png]}	{
				$widget image create end -image [image create photo -file $iconsdir/file_icon.png]
			} else {$widget insert end {f}}
			return
		}
		if {[file type $target] == "directory"}	{
			if {[file exists $iconsdir/dir_icon.png]}	{
				$widget image create end -image [image create photo -file $iconsdir/dir_icon.png]
			} else {$widget insert end {D}}
			return
		}
		if {[file type $target] == "link"}		{
			if {[file type [file readlink $target]] == "directory"}	{
				if {[file exists $iconsdir/dir_icon_link.png]}	{
					$widget image create end -image [image create photo -file $iconsdir/dir_icon_link.png]
				} else {$widget insert end {D}}
			} else {
				if {[file exists $iconsdir/file_icon_link.png]}	{
					$widget image create end -image [image create photo -file $iconsdir/file_icon_link.png]
				} else {$widget insert end {f}}
			}
			return
		}
	}

	proc ::opensave::p.EnterFileOrDirectory {args}	{
		catch {set ::opensave::currindex [[focus] index insert]}
		lassign [split $::opensave::currindex "."] ::opensave::CURRLINE ::opensave::CURRCOL
		set _selection [file join $::opensave::CURRENTDIR [$::opensave::FileListColumn get -displaychars $::opensave::CURRLINE.2 "$::opensave::CURRLINE.0 lineend"]]

		# focus on FileListColumn ------------------------
		if {$::opensave::WidgetThatHasFocusNow == $::opensave::FileListColumn}	{
			if {$args == "---"}	{return}

			if {$args == ".."}	{
				set _selection ""
				lappend ::opensave::HISTORYBACK $::opensave::CURRENTDIR
				set ::opensave::HISTORYFWD {}
				set ::opensave::CURRENTDIR [file dirname $::opensave::CURRENTDIR]
				::opensave::p.RunFunction open
				return
			}

			if {[file tail $_selection] == ".."}	{
				set _selection ""
				lappend ::opensave::HISTORYBACK $::opensave::CURRENTDIR
				set ::opensave::HISTORYFWD {}
				set ::opensave::CURRENTDIR [file dirname $::opensave::CURRENTDIR]
				::opensave::p.RunFunction open
				return
			}
			if 	{[file isdirectory $_selection]}	{
				lappend ::opensave::HISTORYBACK $::opensave::CURRENTDIR
				set ::opensave::CURRENTDIR $::opensave::SELECTEDFILE
				set ::opensave::HISTORYFWD {}
				::opensave::p.Update.Widgets.On.Any.Action
				::opensave::p.RunFunction open
			}
			if {[file isfile $_selection]}	{set ::opensave::OUTPUT $_selection}
		}
		# focus on pathline ------------------------------
		if {$::opensave::WidgetThatHasFocusNow == $::opensave::pathline}	{
			$::opensave::pathline selection clear
			$::opensave::FileListColumn tag remove "sel" 1.0 end

			set ::opensave::filterline [$::opensave::pathline get]
			set ::opensave::usingfilter 1
			if {$::opensave::CURRENTDIR != [lindex $::opensave::HISTORYBACK end]}	{
				lappend ::opensave::HISTORYBACK $::opensave::CURRENTDIR
			}
			set ::opensave::CURRENTDIR $::opensave::filterline
			set ::opensave::HISTORYFWD {}
			::opensave::p.Update.Widgets.On.Any.Action
			::opensave::p.RunFunction open
		}
		# focus on bookmarks ----------------------------
		if {$::opensave::WidgetThatHasFocusNow == $::opensave::bookmarks}	{
			$::opensave::pathline selection clear
			$::opensave::FileListColumn tag remove "sel" 1.0 end

			set ::opensave::currindex [$::opensave::bookmarks index insert]
			lassign [split $::opensave::currindex "."] ::opensave::bookmarkline ::opensave::bookmarkcol
			set _selection [$::opensave::bookmarks get -displaychars $::opensave::bookmarkline.0 "$::opensave::bookmarkline.0 lineend"]

			# check if it's a quickdial bookmark
			if {[regexp {^([0-9]) - (.+)$} $_selection -> ProbableQuickdialNumber ProbableQuickdialName]} {
				if {[lindex $::opensave::cfg::settings(XQuickdial$ProbableQuickdialNumber) 0] == $ProbableQuickdialName}	{
					set _bookmarkpath [lindex $::opensave::cfg::settings(XQuickdial$ProbableQuickdialNumber) 1]
					if 	{[file isdirectory $_bookmarkpath]}	{
						lappend ::opensave::HISTORYBACK $::opensave::CURRENTDIR
						set ::opensave::CURRENTDIR $_bookmarkpath
						set ::opensave::HISTORYFWD {}
						::opensave::p.Update.Widgets.On.Any.Action
						::opensave::p.RunFunction open
						return
					}
					if {[file isfile $_selection]}	{return $_selection}
				}
			}

			# check if it's a generic bookmark
			set _lindex [lsearch -exact $::opensave::cfg::settings(XGenericBookmarks) $_selection]
			set _bookmarkname [lindex $::opensave::cfg::settings(XGenericBookmarks) $_lindex]
			incr _lindex
			set _bookmarkpath [lindex $::opensave::cfg::settings(XGenericBookmarks) $_lindex]

			if 	{[file isdirectory $_bookmarkpath]}	{
				lappend ::opensave::HISTORYBACK $::opensave::CURRENTDIR
				set ::opensave::CURRENTDIR $_bookmarkpath
				set ::opensave::HISTORYFWD {}
				::opensave::p.Update.Widgets.On.Any.Action
				::opensave::p.RunFunction open
				return
			}
			if {[file isfile $_selection]}	{return $_selection}
		}
	}

	proc ::opensave::p.Navigate {direction}	{
		if {$direction == "back"}	{
			if {[llength $::opensave::HISTORYBACK] < 1} {return}
			set ::opensave::HISTORYFWD [linsert $::opensave::HISTORYFWD 0 $::opensave::CURRENTDIR]
			set ::opensave::CURRENTDIR [lindex $::opensave::HISTORYBACK end]
			set ::opensave::HISTORYBACK [lrange $::opensave::HISTORYBACK 0 end-1]
			::opensave::p.RunFunction open
		}
		if {$direction == "forward"}	{
			if {[llength $::opensave::HISTORYFWD] == 0} {return}
			lappend ::opensave::HISTORYBACK $::opensave::CURRENTDIR
			set ::opensave::CURRENTDIR [lindex $::opensave::HISTORYFWD 0]
			if {[llength $::opensave::HISTORYFWD] > 1}	{
				set ::opensave::HISTORYFWD [lrange $::opensave::HISTORYFWD 1 end]
			} else {set ::opensave::HISTORYFWD {}}
			::opensave::p.RunFunction open
		}
	}

	proc ::opensave::p.fixWidth	{}	{
		if 	{[info exists ::opensave::OwnerColumn] && [info exists ::opensave::owner_longest]}	{
			$::opensave::OwnerColumn configure -width $::opensave::owner_longest
		}
		if 	{[info exists ::opensave::PermissionColumn]}	{
			$::opensave::PermissionColumn configure -width 14 -bd 0
		}
		if 	{[info exists ::opensave::DateColumn]}	{
			$::opensave::DateColumn configure -width 17 -bd 0
		}
		if 	{[info exists ::opensave::SizeColumn] && [info exists ::opensave::size_longest]}	{
			$::opensave::SizeColumn configure -width $::opensave::size_longest
		}
	}

	proc ::opensave::p.SortSwitch {sorting}	{
		if {$sorting == "alpha"}	{
			if {$::opensave::cfg::settings(Sorting1) == "alpha"}	{
				if {$::opensave::cfg::settings(Sorting2) == "increase"}	{
					set ::opensave::cfg::settings(Sorting2) "decrease"
				} else {set ::opensave::cfg::settings(Sorting2) "increase"}
			}
			set ::opensave::cfg::settings(Sorting1) "alpha"
			$::opensave::topview.topright1.button1 configure -text "a = alpha *"
			$::opensave::topview.topright1.button2 configure -text "s = size"
			$::opensave::topview.topright1.button3 configure -text "d = date"
			$::opensave::topview.topright1.button4 configure -text "p = permission"
			$::opensave::topview.topright1.button5 configure -text "o = owner"
		}
		if {$sorting == "size"}	{
			if {$::opensave::cfg::settings(Sorting1) == "size"}	{
				if {$::opensave::cfg::settings(Sorting2) == "increase"}	{
					set ::opensave::cfg::settings(Sorting2) "decrease"
				} else {set ::opensave::cfg::settings(Sorting2) "increase"}
			}
			set ::opensave::cfg::settings(Sorting1) "size"
			$::opensave::topview.topright1.button1 configure -text "a = alpha"
			$::opensave::topview.topright1.button2 configure -text "s = size *"
			$::opensave::topview.topright1.button3 configure -text "d = date"
			$::opensave::topview.topright1.button4 configure -text "p = permission"
			$::opensave::topview.topright1.button5 configure -text "o = owner"
		}
		if {$sorting == "date"}	{
			if {$::opensave::cfg::settings(Sorting1) == "date"}	{
				if {$::opensave::cfg::settings(Sorting2) == "increase"}	{
					set ::opensave::cfg::settings(Sorting2) "decrease"
				} else {set ::opensave::cfg::settings(Sorting2) "increase"}
			}
			set ::opensave::cfg::settings(Sorting1) "date"
			$::opensave::topview.topright1.button1 configure -text "a = alpha"
			$::opensave::topview.topright1.button2 configure -text "s = size"
			$::opensave::topview.topright1.button3 configure -text "d = date *"
			$::opensave::topview.topright1.button4 configure -text "p = permission"
			$::opensave::topview.topright1.button5 configure -text "o = owner"
		}
		if {$sorting == "perm"}	{
			if {$::opensave::cfg::settings(Sorting1) == "perm"}	{
				if {$::opensave::cfg::settings(Sorting2) == "increase"}	{
					set ::opensave::cfg::settings(Sorting2) "decrease"
				} else {set ::opensave::cfg::settings(Sorting2) "increase"}
			}
			set ::opensave::cfg::settings(Sorting1) "perm"
			$::opensave::topview.topright1.button1 configure -text "a = alpha"
			$::opensave::topview.topright1.button2 configure -text "s = size"
			$::opensave::topview.topright1.button3 configure -text "d = date"
			$::opensave::topview.topright1.button4 configure -text "p = permission *"
			$::opensave::topview.topright1.button5 configure -text "o = owner"
		}
		if {$sorting == "owner"}	{
			if {$::opensave::cfg::settings(Sorting1) == "owner"}	{
				if {$::opensave::cfg::settings(Sorting2) == "increase"}	{
					set ::opensave::cfg::settings(Sorting2) "decrease"
				} else {set ::opensave::cfg::settings(Sorting2) "increase"}
			}
			set ::opensave::cfg::settings(Sorting1) "owner"
			$::opensave::topview.topright1.button1 configure -text "a = alpha"
			$::opensave::topview.topright1.button2 configure -text "s = size"
			$::opensave::topview.topright1.button3 configure -text "d = date"
			$::opensave::topview.topright1.button4 configure -text "p = permission"
			$::opensave::topview.topright1.button5 configure -text "o = owner *"
		}

		set _fp [open $::opensave::CONFIGFILE w]
		foreach _item [lsort [array names ::opensave::cfg::settings]]	{
			puts $_fp "$_item = $::opensave::cfg::settings($_item)"
		}
		close $_fp

		::opensave::p.RunFunction open
	}

	proc ::opensave::p.ToggleHidden {}	{
		if {$::opensave::cfg::settings(HiddenFiles) == "show"}	{
			set ::opensave::cfg::settings(HiddenFiles) "hide"
			$::opensave::topview.topright2.button6 configure -text "h = hidden (off)"
		} else {
			set ::opensave::cfg::settings(HiddenFiles) "show"
			$::opensave::topview.topright2.button6 configure -text "h = hidden (on)"
		}

		set _fp [open $::opensave::CONFIGFILE w]
		foreach _item [lsort [array names ::opensave::cfg::settings]]	{
			puts $_fp "$_item = $::opensave::cfg::settings($_item)"
		}
		close $_fp

		::opensave::p.RunFunction open
	}

	proc ::opensave::p.CopyPath {}	{
		selection own
		clipboard clear -displayof .
		clipboard append -displayof . $::opensave::SELECTEDFILE
	}

	proc ::opensave::p.center_window {argW}  {
		wm withdraw $argW
		update idletasks
		set _x [expr [winfo screenwidth $argW]/2 - [winfo reqwidth $argW]/2 - [winfo vrootx [winfo parent $argW]]]
		set _y [expr [winfo screenheight $argW ]/2 - [winfo reqheight $argW]/2 - [winfo vrooty [winfo parent $argW]]]

		# two monitor hack
		set _screeninfo [exec xrandr --prop]
		foreach i [split $_screeninfo "\n"] {
			if [regexp -line {^[^ ]+ connected .*} $i _match] {lappend _monitors $_match}
		}
		catch {if	{[llength $_monitors] > 1}	{set _x [expr $_x + 640]}}

		# lower height hack
		set _y [expr $_y + 300]

		wm geom $argW +$_x+$_y
		wm deiconify $argW
	}

	proc ::opensave::p.MakeWidgets  {}  	{ 
	# ----------------- MAKE ALL WIDGETS -----------------------
		package require Tk
		ttk::style theme use alt
		wm withdraw .
		eval destroy [winfo children .]
		catch {destroy .opensave}
		set ::opensave::w [toplevel .opensave]
		wm resizable $::opensave::w 1 1
		tk appname "OpenSave"
		wm title $::opensave::w OpenSave
		
		# -------------- OUTER FRAME --------------
		ttk::frame		$::opensave::w.outer
		$::opensave::w.outer configure -relief solid -borderwidth 1
		pack $::opensave::w.outer -fill both -expand 1
		# ---------------- TOPVIEW ----------------
		ttk::frame		$::opensave::w.outer.topviewfr
		text            $::opensave::w.outer.topviewfr.topview
		set ::opensave::topview	$::opensave::w.outer.topviewfr.topview
		$::opensave::topview configure -font $::opensave::cfg::settings(HeaderFont)
		$::opensave::topview configure -background $::opensave::cfg::settings(HeaderBg)
		$::opensave::topview configure -foreground $::opensave::cfg::settings(HeaderFg)
		$::opensave::topview configure -wrap none
		$::opensave::topview configure -padx 16 -pady 16
		$::opensave::topview configure -takefocus 0 -exportselection 1
		$::opensave::topview configure -height 5
		
		pack $::opensave::w.outer.topviewfr -fill both -expand 0
		pack $::opensave::topview -side left -fill both -expand 1

		frame $::opensave::topview.topleft1
		$::opensave::topview.topleft1 configure -relief solid -borderwidth 0
		$::opensave::topview.topleft1 configure -height 1 -width 1000
		$::opensave::topview.topleft1 configure -background $::opensave::cfg::settings(TextBg)
		grid $::opensave::topview.topleft1 -column 1 -row 1 -columnspan 2 -rowspan 2 -sticky nw
		text $::opensave::topview.topleft1.opensavelabel
		$::opensave::topview.topleft1.opensavelabel configure -height 1 -width 70
		$::opensave::topview.topleft1.opensavelabel configure -relief flat -borderwidth 4
		$::opensave::topview.topleft1.opensavelabel configure -background $::opensave::cfg::settings(TextBg)
		$::opensave::topview.topleft1.opensavelabel configure -font $::opensave::cfg::settings(HeaderFont)
		$::opensave::topview.topleft1.opensavelabel configure -spacing1 10 -spacing3 10
		grid $::opensave::topview.topleft1.opensavelabel -column 1 -row 1 -sticky w
		$::opensave::topview.topleft1.opensavelabel insert end " OPEN"
		$::opensave::topview.topleft1.opensavelabel configure -state disabled -takefocus 0
		
		frame $::opensave::topview.topleft2
		$::opensave::topview.topleft2 configure -relief solid -borderwidth 0
		$::opensave::topview.topleft2 configure -height 100 -width 1000
		$::opensave::topview.topleft2 configure -background $::opensave::cfg::settings(TextBg)
		grid $::opensave::topview.topleft2 -column 1 -row 2 -columnspan 2 -rowspan 2 -sticky sw
		text $::opensave::topview.topleft2.opensavelabel
		$::opensave::topview.topleft2.opensavelabel configure -height 4 -width 70
		$::opensave::topview.topleft2.opensavelabel configure -relief flat -borderwidth 4
		$::opensave::topview.topleft2.opensavelabel configure -background $::opensave::cfg::settings(TextBg)
		$::opensave::topview.topleft2.opensavelabel configure -font $::opensave::cfg::settings(HeaderFont)
		$::opensave::topview.topleft2.opensavelabel configure -spacing1 1 -spacing3 1
		grid $::opensave::topview.topleft2.opensavelabel -column 1 -row 1 -sticky w
		$::opensave::topview.topleft2.opensavelabel insert end " "
		::opensave::p.InsertCorrectIcon $::opensave::topview.topleft2.opensavelabel $::opensave::CURRENTDIR
		after idle [$::opensave::topview.topleft2.opensavelabel insert end "  [file tail $::opensave::CURRENTDIR]\n"]
		$::opensave::topview.topleft2.opensavelabel insert end "       the current directory"
		$::opensave::topview.topleft2.opensavelabel configure -state disabled -takefocus 0

		frame $::opensave::topview.toprightghost1
		$::opensave::topview.toprightghost1 configure -relief solid -bd 0
		$::opensave::topview.toprightghost1 configure -height 160 -width 620
		$::opensave::topview.toprightghost1 configure -background $::opensave::cfg::settings(HeaderBg)
		$::opensave::topview.toprightghost1 configure -padx 1 -pady 1
		grid $::opensave::topview.toprightghost1 -column 20 -row 1 -columnspan 5 -rowspan 3 -sticky nw
		button $::opensave::topview.toprightghost1.button1 -relief flat -bd 0 -highlightthickness 0 \
			-bg $::opensave::cfg::settings(HeaderBg) -activebackground $::opensave::cfg::settings(HeaderBg) \
			-takefocus 0 -width 4 -text "" -font $::opensave::cfg::settings(TextFont)
		button $::opensave::topview.toprightghost1.button2 -relief flat -bd 0 -activebackground $::opensave::cfg::settings(HeaderBg) \
			-highlightthickness 0 -bg $::opensave::cfg::settings(HeaderBg) \
			-takefocus 0 -width 4 -text "" -font $::opensave::cfg::settings(TextFont)
		button $::opensave::topview.toprightghost1.button3 -relief flat -bd 0 -highlightthickness 0 \
			-bg $::opensave::cfg::settings(HeaderBg) -activebackground $::opensave::cfg::settings(HeaderBg)\
			-takefocus 0 -width 4 -text "" -font $::opensave::cfg::settings(TextFont)
		button $::opensave::topview.toprightghost1.button4 -relief flat -bd 0 -highlightthickness 0 \
			-bg $::opensave::cfg::settings(HeaderBg) -activebackground $::opensave::cfg::settings(HeaderBg)\
			-takefocus 0 -width 4 -text "" -font $::opensave::cfg::settings(TextFont)
		button $::opensave::topview.toprightghost1.button5 -relief flat -bd 0 -highlightthickness 0 \
			-bg $::opensave::cfg::settings(HeaderBg) -activebackground $::opensave::cfg::settings(HeaderBg)\
			-takefocus 0 -width 4 -text "" -font $::opensave::cfg::settings(TextFont)
		foreach i {1 2 3 4 5} {pack $::opensave::topview.toprightghost1.button$i -side top}

		frame $::opensave::topview.topright1
		$::opensave::topview.topright1 configure -relief solid -borderwidth 0
		$::opensave::topview.topright1 configure -height 160 -width 620
		$::opensave::topview.topright1 configure -background $::opensave::cfg::settings(HeaderBg)
		$::opensave::topview.topright1 configure -padx 1 -pady 1
		$::opensave::topview.topright1 configure -cursor arrow
		grid $::opensave::topview.topright1 -column 80 -row 1 -columnspan 5 -rowspan 3 -sticky ne
		button $::opensave::topview.topright1.button1 -relief flat -borderwidth 4 -bg #FFC458 -takefocus 0 -width 10 -font $::opensave::cfg::settings(TextFont)
			if {$::opensave::cfg::settings(Sorting1) == "alpha"} {
				$::opensave::topview.topright1.button1 configure -text "a = alpha *"
			} else {$::opensave::topview.topright1.button1 configure -text "a = alpha"}
		button $::opensave::topview.topright1.button2 -relief flat -borderwidth 4 -bg #FFC458 -takefocus 0 -width 10 -font $::opensave::cfg::settings(TextFont)
			if {$::opensave::cfg::settings(Sorting1) == "size"} {
				$::opensave::topview.topright1.button2 configure -text "s = size *"
			} else {$::opensave::topview.topright1.button2 configure -text "s = size"}
		button $::opensave::topview.topright1.button3 -relief flat -borderwidth 4 -bg #FFC458 -takefocus 0 -width 10 -font $::opensave::cfg::settings(TextFont)
			if {$::opensave::cfg::settings(Sorting1) == "date"} {
				$::opensave::topview.topright1.button3 configure -text "d = date *"
			} else {$::opensave::topview.topright1.button3 configure -text "d = date"}
		button $::opensave::topview.topright1.button4 -relief flat -borderwidth 4 -bg #FFC458 -takefocus 0 -width 10 -font $::opensave::cfg::settings(TextFont)
			if {$::opensave::cfg::settings(Sorting1) == "perm"} {
				$::opensave::topview.topright1.button4 configure -text "p = permission *"
			} else {$::opensave::topview.topright1.button4 configure -text "p = permission"}
		button $::opensave::topview.topright1.button5 -relief flat -borderwidth 4 -bg #FFC458 -takefocus 0 -width 10 -font $::opensave::cfg::settings(TextFont)
			if {$::opensave::cfg::settings(Sorting1) == "owner"} {
				$::opensave::topview.topright1.button5 configure -text "o = owner *"
			} else {$::opensave::topview.topright1.button5 configure -text "o = owner"}
		foreach i {1 2 3 4 5} {pack $::opensave::topview.topright1.button$i -side top}

		frame $::opensave::topview.toprightghost2
		$::opensave::topview.toprightghost2 configure -relief solid -bd 0
		$::opensave::topview.toprightghost2 configure -height 160 -width 620
		$::opensave::topview.toprightghost2 configure -background $::opensave::cfg::settings(HeaderBg)
		$::opensave::topview.toprightghost2 configure -padx 1 -pady 1
		grid $::opensave::topview.toprightghost2 -column 120 -row 1 -columnspan 5 -rowspan 3 -sticky nw
		button $::opensave::topview.toprightghost2.button1 -relief flat -bd 0 -highlightthickness 0 \
			-bg $::opensave::cfg::settings(HeaderBg) -activebackground $::opensave::cfg::settings(HeaderBg) \
			-takefocus 0 -width 4 -text "" -font $::opensave::cfg::settings(TextFont)
		button $::opensave::topview.toprightghost2.button2 -relief flat -bd 0 -activebackground $::opensave::cfg::settings(HeaderBg) \
			-highlightthickness 0 -bg $::opensave::cfg::settings(HeaderBg) \
			-takefocus 0 -width 4 -text "" -font $::opensave::cfg::settings(TextFont)
		button $::opensave::topview.toprightghost2.button3 -relief flat -bd 0 -highlightthickness 0 \
			-bg $::opensave::cfg::settings(HeaderBg) -activebackground $::opensave::cfg::settings(HeaderBg)\
			-takefocus 0 -width 4 -text "" -font $::opensave::cfg::settings(TextFont)
		button $::opensave::topview.toprightghost2.button4 -relief flat -bd 0 -highlightthickness 0 \
			-bg $::opensave::cfg::settings(HeaderBg) -activebackground $::opensave::cfg::settings(HeaderBg)\
			-takefocus 0 -width 4 -text "" -font $::opensave::cfg::settings(TextFont)
		button $::opensave::topview.toprightghost2.button5 -relief flat -bd 0 -highlightthickness 0 \
			-bg $::opensave::cfg::settings(HeaderBg) -activebackground $::opensave::cfg::settings(HeaderBg)\
			-takefocus 0 -width 4 -text "" -font $::opensave::cfg::settings(TextFont)
		foreach i {1 2 3 4 5} {pack $::opensave::topview.toprightghost2.button$i -side top}

		frame $::opensave::topview.topright2
		$::opensave::topview.topright2 configure -relief solid -borderwidth 0
		$::opensave::topview.topright2 configure -height 160 -width 620
		$::opensave::topview.topright2 configure -background $::opensave::cfg::settings(HeaderBg)
		$::opensave::topview.topright2 configure -padx 1 -pady 1
		$::opensave::topview.topright2 configure -cursor arrow
		grid $::opensave::topview.topright2 -column 160 -row 1 -columnspan 5 -rowspan 3 -sticky ne
		button $::opensave::topview.topright2.button6 -relief flat -borderwidth 4 -bg #FFC458 -takefocus 0 -width 10 -font $::opensave::cfg::settings(TextFont)
			if {$::opensave::cfg::settings(HiddenFiles) == "show"} {
				$::opensave::topview.topright2.button6 configure -text "h = hidden (on)"
			} else {$::opensave::topview.topright2.button6 configure -text "h = hidden (off)"}
		button $::opensave::topview.topright2.button7 -relief flat -borderwidth 4 -bg #FFC458 -takefocus 0 -width 10 -text "c = copy path" -font $::opensave::cfg::settings(TextFont)
		button $::opensave::topview.topright2.button8 -relief flat -borderwidth 4 -bg #FFC458 -takefocus 0 -width 10 -text "b = bookmark" -font $::opensave::cfg::settings(TextFont)
		button $::opensave::topview.topright2.button9 -relief flat -borderwidth 4 -bg #FFC458 -takefocus 0 -width 10 -text "tab or / = filter" -font $::opensave::cfg::settings(TextFont)
		button $::opensave::topview.topright2.button10 -relief flat -borderwidth 4 -bg #FFC458 -takefocus 0 -width 10 -text "t = toggle top" -font $::opensave::cfg::settings(TextFont)
		foreach i {6 7 8 9 10} {pack $::opensave::topview.topright2.button$i -side top}

		$::opensave::topview delete 1.0 end
		$::opensave::topview insert end "OPEN"

		# ---------------- PATH LINE ----------------
		ttk::frame		$::opensave::w.outer.pathlinefr
		button			$::opensave::w.outer.pathlinefr.histback -takefocus 0 -text [subst -nocommands "\\u25c0"] -command [list ::opensave::p.Navigate "back"]
		button			$::opensave::w.outer.pathlinefr.histfwd -takefocus 0 -text  [subst -nocommands "\\u25b6"] -command [list ::opensave::p.Navigate "forward"]
		pack $::opensave::w.outer.pathlinefr.histback -side left
		pack $::opensave::w.outer.pathlinefr.histfwd -side left
		
		if {$::opensave::argAction == "save"}	{
			button			$::opensave::w.outer.pathlinefr.save
			$::opensave::w.outer.pathlinefr.save configure -takefocus 0
			$::opensave::w.outer.pathlinefr.save configure -text "SAVE AS..."
			$::opensave::w.outer.pathlinefr.save configure -bg #000000
			$::opensave::w.outer.pathlinefr.save configure -fg #ffffff
			$::opensave::w.outer.pathlinefr.save configure -font $::opensave::cfg::settings(TextFont)
			$::opensave::w.outer.pathlinefr.save configure -width 12
			$::opensave::w.outer.pathlinefr.save configure -command [list ::opensave::p.Navigate "forward"]
			pack $::opensave::w.outer.pathlinefr.save -side left
		}

		entry           $::opensave::w.outer.pathlinefr.pathline
		set ::opensave::pathline		$::opensave::w.outer.pathlinefr.pathline
		$::opensave::pathline configure -background $::opensave::cfg::settings(TextBg) -foreground $::opensave::cfg::settings(TextFg)
		$::opensave::pathline configure -font $::opensave::cfg::settings(TextFont)
		$::opensave::pathline configure -takefocus 1 -exportselection 1
		$::opensave::pathline configure -state normal
		$::opensave::pathline configure -textvariable ::opensave::CURRENTDIR

		pack $::opensave::w.outer.pathlinefr -fill both -expand 0
		pack $::opensave::pathline -side left -fill both -expand 1

		# ---------------- THREE PANES ----------------
		# ------------------- FRAME -------------------
		set ::opensave::twopanesframe [ttk::frame $::opensave::w.outer.threepanesframe]
		set ::opensave::panedwindow   [panedwindow $::opensave::w.outer.threepanesframe.threepanes -orient horizontal]

		$::opensave::twopanesframe configure
		$::opensave::panedwindow configure

		pack $::opensave::panedwindow -expand 1 -fill both
		pack $::opensave::twopanesframe -expand 1 -fill both
		# ------------------ PANE 1 -------------------
		ttk::frame		$::opensave::panedwindow.frame_1
		$::opensave::panedwindow.frame_1 configure -borderwidth 0
		$::opensave::panedwindow.frame_1 configure -takefocus 0
		pack $::opensave::panedwindow.frame_1 -expand 1 -fill both

		ttk::label		$::opensave::panedwindow.frame_1.label_bookmarks
		$::opensave::panedwindow.frame_1.label_bookmarks configure -text "Bookmarks"
		$::opensave::panedwindow.frame_1.label_bookmarks configure -font $::opensave::cfg::settings(TextFont)
		$::opensave::panedwindow.frame_1.label_bookmarks configure -takefocus 0
		pack $::opensave::panedwindow.frame_1.label_bookmarks -side top

		text 			$::opensave::panedwindow.frame_1.bookmarks
		set ::opensave::bookmarks $::opensave::panedwindow.frame_1.bookmarks
		$::opensave::bookmarks configure -background $::opensave::cfg::settings(TextBg) -foreground $::opensave::cfg::settings(TextFg)
		$::opensave::bookmarks configure -wrap none -font $::opensave::cfg::settings(TextFont) -padx 4 -pady 2
		$::opensave::bookmarks configure -takefocus 1
		$::opensave::bookmarks configure -spacing1 1 -spacing2 1 -spacing3 1
		$::opensave::bookmarks configure -width 16 -bd 0
		$::opensave::bookmarks configure -setgrid true
		$::opensave::bookmarks configure -cursor arrow
		$::opensave::bookmarks tag configure "selected" -foreground #ffffff -background #000000
		$::opensave::bookmarks configure -state normal
		pack $::opensave::bookmarks -fill both -expand 1 -side bottom
		
		set bookmarkentries ""
		
		# collect Quickdial entry names
		set quickdialentries ""
		foreach k [lsort [array names ::opensave::cfg::settings]]	{
			if {[string range $k 0 9] == "XQuickdial"}	{
				lappend bookmarkentries "[string range $k 10 10] - [lindex $::opensave::cfg::settings($k) 0]"
			}
		}
		# collect generic bookmark entry names
		if {[info exists ::opensave::cfg::settings(XGenericBookmarks)]}	{
			for {set i 0} {$i < [llength $::opensave::cfg::settings(XGenericBookmarks)]} {incr i} {
				lappend bookmarkentries "[lindex $::opensave::cfg::settings(XGenericBookmarks) $i]"
				incr i
			}
		}

		# insert all entries into widget
		$::opensave::bookmarks configure -state normal
		$::opensave::bookmarks delete 1.0 end
		if {[llength $bookmarkentries] > 0}	{
			for {set i 0} {$i < [llength $bookmarkentries]} {incr i} {
				$::opensave::bookmarks insert end [lindex $bookmarkentries $i]
				if {$i != [expr [llength $bookmarkentries] - 1]}	{
					$::opensave::bookmarks insert end "\n"
				}
			}
		}
		$::opensave::bookmarks mark set insert "1.0 linestart"
		$::opensave::bookmarks configure -state disabled
		# ------------------ PANE 2 -------------------
		proc ::opensave::yset {args} {
			$::opensave::panedwindow.frame_2.scrollv set {*}$args
			yview moveto [lindex [$::opensave::panedwindow.frame_2.scrollv get] 0]
		}
		proc ::opensave::yview {args} {
			foreach fe $::opensave::COLUMNS	{
				[set [join [list ::opensave:: $fe Column] ""]] yview {*}$args
			}
		}

		ttk::frame 		$::opensave::panedwindow.frame_2
		$::opensave::panedwindow.frame_2 configure -borderwidth 0

		ttk::scrollbar	$::opensave::panedwindow.frame_2.scrollv -orient vertical -command [list $::opensave::panedwindow.frame_2.filelist yview]
		set ::opensave::scrollbar $::opensave::panedwindow.frame_2.scrollv
		pack $::opensave::scrollbar -fill y -side right

		foreach fe $::opensave::COLUMNS	{
			set _pathlong 	[join [list $::opensave::panedwindow.frame_2. [string tolower $fe]] ""]
			set _pathshort 		[join [list ::opensave:: $fe Column] ""]
			text 			$_pathlong
			set $_pathshort $_pathlong
			[set $_pathshort] configure -font $::opensave::cfg::TextFont
			[set $_pathshort] configure -background $::opensave::cfg::settings(TextBg)
			[set $_pathshort] configure -foreground $::opensave::cfg::settings(TextFg)
			[set $_pathshort] configure -width 8 -bd 0
			[set $_pathshort] configure -padx 0 -pady 1
			[set $_pathshort] configure -spacing1 1 -spacing2 1 -spacing3 1
			[set $_pathshort] configure -wrap none
			[set $_pathshort] configure -takefocus 0 -exportselection 0 -undo 0
			[set $_pathshort] configure -state normal
			[set $_pathshort] configure -exportselection 1 -undo 0
			[set $_pathshort] configure -setgrid true
			[set $_pathshort] configure -cursor arrow
			[set $_pathshort] configure -yscrollcommand ::opensave::yset
			[set $_pathshort] tag configure "selected" -foreground #ffffff -background #000000
			pack [set $_pathshort] -fill both -expand 1 -side left
		}

		
		$::opensave::FileListColumn configure -takefocus 1
		$::opensave::FileListColumn configure -width 50
		$::opensave::SizeColumn configure -width 9
		$::opensave::DateColumn configure -width 17
		$::opensave::PermissionColumn configure -width 14
		$::opensave::OwnerColumn configure -width 20

		# ------------ ADD THE FRAMES TO THE PANES -------------
		$::opensave::panedwindow add $::opensave::panedwindow.frame_1
		$::opensave::panedwindow add $::opensave::panedwindow.frame_2
		# ---------------- STATUS BAR ----------------
		ttk::frame 		$::opensave::w.outer.statusbarfr
		ttk::label 		$::opensave::w.outer.statusbar
		set ::opensave::statusbar $::opensave::w.outer.statusbar
		$::opensave::statusbar configure -font $::opensave::cfg::settings(StatusFont)
		$::opensave::statusbar configure -background $::opensave::cfg::settings(StatusBg) -foreground $::opensave::cfg::settings(StatusFg)
		$::opensave::statusbar configure -relief ridge
		$::opensave::statusbar configure -anchor w
		$::opensave::statusbar configure -text "File is saved."

		pack $::opensave::w.outer.statusbarfr -fill x -expand 0 -side bottom
		pack $::opensave::w.outer.statusbar -fill x -expand 0


		$::opensave::topview.topright1.button1 configure -command [list ::opensave::p.SortSwitch "alpha"]
		$::opensave::topview.topright1.button2 configure -command [list ::opensave::p.SortSwitch "size"]
		$::opensave::topview.topright1.button3 configure -command [list ::opensave::p.SortSwitch "date"]
		$::opensave::topview.topright1.button4 configure -command [list ::opensave::p.SortSwitch "perm"]
		$::opensave::topview.topright1.button5 configure -command [list ::opensave::p.SortSwitch "owner"]
		$::opensave::topview.topright2.button6 configure -command ::opensave::p.ToggleHidden
		$::opensave::topview.topright2.button7 configure -command ::opensave::p.CopyPath
		$::opensave::topview.topright2.button8 configure -command [list ::opensave::cfg::manage::p.AddBookmarkWidget]
		$::opensave::topview.topright2.button9 configure -command [list focus $::opensave::pathline; event generate $::opensave::pathline <End>]
		$::opensave::topview.topright2.button10 configure -command ::opensave::p.ToggleTop


		# ---------------- BINDINGS ----------------
		bind $::opensave::FileListColumn	<Key> 			{after idle [list ::opensave::p.Update.Widgets.On.Any.Action %K]}
		bind $::opensave::FileListColumn 	<Button>		{after idle [list ::opensave::p.Update.Widgets.On.Any.Action]}
		bind $::opensave::FileListColumn	<Home>			{$::opensave::FileListColumn mark set insert 1.0; ::opensave::p.Update.Widgets.On.Any.Action}
		bind $::opensave::FileListColumn	<End>			{$::opensave::FileListColumn mark set insert end; ::opensave::p.Update.Widgets.On.Any.Action}
		bind $::opensave::FileListColumn	<Return>		{set ::opensave::RETURN [::opensave::p.EnterFileOrDirectory]}
		bind $::opensave::FileListColumn	<Double-ButtonPress-1>	{set ::opensave::RETURN [::opensave::p.EnterFileOrDirectory]; break; $::opensave::FileListColumn tag remove "sel" 1.0 end}

		bind $::opensave::FileListColumn	<a> 			{::opensave::p.SortSwitch "alpha"}
		bind $::opensave::FileListColumn	<s> 			{::opensave::p.SortSwitch "size"}
		bind $::opensave::FileListColumn	<d> 			{::opensave::p.SortSwitch "date"}
		bind $::opensave::FileListColumn	<p> 			{::opensave::p.SortSwitch "perm"}
		bind $::opensave::FileListColumn	<o> 			{::opensave::p.SortSwitch "owner"}
		bind $::opensave::FileListColumn	<h> 			{::opensave::p.ToggleHidden}
		bind $::opensave::FileListColumn	<t> 			{::opensave::p.ToggleTop}
		bind $::opensave::FileListColumn	<c> 			{::opensave::p.CopyPath}
		bind $::opensave::FileListColumn	<slash>			{focus $::opensave::pathline; event generate $::opensave::pathline <End>}
		bind $::opensave::FileListColumn	<b> 			{::opensave::cfg::manage::p.AddBookmarkWidget}

		bind $::opensave::FileListColumn	<Left>			{::opensave::p.Navigate "back"}
		bind $::opensave::FileListColumn	<Right>			{::opensave::p.Navigate "forward"}
		bind $::opensave::FileListColumn	<Alt_L><Left>	{::opensave::p.Navigate "back"}
		bind $::opensave::FileListColumn	<Alt_L><Right>	{::opensave::p.Navigate "forward"}
		bind $::opensave::FileListColumn	<Alt_L><Up>		{::opensave::p.EnterFileOrDirectory ".."}
		bind $::opensave::pathline			<Alt_L><Up>		{::opensave::p.EnterFileOrDirectory ".."}
		bind $::opensave::bookmarks			<Alt_L><Up>		{::opensave::p.EnterFileOrDirectory ".."}

		bind $::opensave::bookmarks			<Key> 			{after idle [list ::opensave::p.Update.Widgets.On.Any.Action %K]}
		bind $::opensave::bookmarks			<Home>			{$::opensave::bookmarks mark set insert 1.0; ::opensave::p.Update.Widgets.On.Any.Action}
		bind $::opensave::bookmarks			<End>			{$::opensave::bookmarks mark set insert end; ::opensave::p.Update.Widgets.On.Any.Action}
		bind $::opensave::bookmarks			<FocusIn>		{update idletasks; ::opensave::p.Update.Widgets.On.Any.Action}
		bind $::opensave::bookmarks			<Return>		{set ::opensave::RETURN [::opensave::p.EnterFileOrDirectory]}
		bind $::opensave::bookmarks 		<Button>		{focus $::opensave::bookmarks; after idle [list ::opensave::p.Update.Widgets.On.Any.Action]}
		bind $::opensave::bookmarks			<Double-ButtonPress-1>	{set ::opensave::RETURN [::opensave::p.EnterFileOrDirectory]; break;}

		bind $::opensave::pathline			<Return>		{set ::opensave::RETURN [::opensave::p.EnterFileOrDirectory]}

		bind $::opensave::w					<Configure> {::opensave::p.fixWidth; break}
		bind $::opensave::w					<Alt_L><d> 	{::opensave::p.fixWidth; break}
		bind $::opensave::w					<Alt_L><q> 	{exit 0}
		bind $::opensave::w					<Alt_L><Q> 	{exit 0}
		bind $::opensave::w					<Escape>	{exit 0}
		wm protocol $::opensave::w WM_DELETE_WINDOW  		{exit 0}
		# ---------------- BINDINGS ----------------

		set ::opensave::PreviouslySelectedLine 1
		set ::opensave::filterline {}
		
		if {$::opensave::cfg::settings(TopPane) == "hide"}	{
				set ::packinfo [pack info $::opensave::w.outer.topviewfr]
				pack forget $::opensave::w.outer.topviewfr
				update idletasks
				::opensave::p.center_window $::opensave::w
				::opensave::p.Update.Widgets.On.Any.Action
				set ::opensave::cfg::settings(TopPane) "hide"
		}

		::opensave::p.center_window $::opensave::w
	# ----------------- ALL WIDGETS DONE -----------------------
	}



	proc ::opensave::p.ToggleTop {}	{
		if {[winfo ismapped $::opensave::w.outer.topviewfr]}	{
			set ::packinfo [pack info $::opensave::w.outer.topviewfr]
			pack forget $::opensave::w.outer.topviewfr
			update idletasks
			::opensave::p.center_window $::opensave::w
			::opensave::p.Update.Widgets.On.Any.Action
			set ::opensave::cfg::settings(TopPane) "hide"
		} else {
			pack {*}[list $::opensave::w.outer.topviewfr {*}$::packinfo -before $::opensave::w.outer.pathlinefr]
			update idletasks
			::opensave::p.center_window $::opensave::w
			::opensave::p.Update.Widgets.On.Any.Action
			set ::opensave::cfg::settings(TopPane) "show"
		}
		set _fp [open $::opensave::CONFIGFILE w]
		foreach _item [lsort [array names ::opensave::cfg::settings]]	{
			puts $_fp "$_item = $::opensave::cfg::settings($_item)"
		}
		close $_fp
	}

	proc ::opensave::cfg::manage::p.BookmarkExists {argExistList} {

		set Name [lindex $argExistList 0]
		if {$Name != ""}	{set WhatExists "name"}
		set Path [lindex $argExistList 1]
		if {$Path != ""} {set WhatExists "path"}
		if {$Name != "" && $Path != ""}	{set WhatExists "both"}
		if {[lindex $argExistList 2] != ""}	{set WhatExists "quickdial"}


		package require Tk
		package require tile
		ttk::style theme use alt
		wm withdraw .
		eval destroy [winfo children .]
		catch {destroy .existing}
		set ::opensave::existing [toplevel .existing]
		wm resizable $::opensave::existing 1 1
		tk appname "Manage Bookmarks"
		wm title $::opensave::existing "Manage Bookmarks"

		if {$WhatExists == "name"}	{
			set _namelindex [lsearch -exact $::opensave::cfg::settings(XGenericBookmarks) $Name]
			if {$_namelindex != -1}	{
				incr _namelindex
				set Path [lindex $::opensave::cfg::settings(XGenericBookmarks) $_namelindex]
			}
			if {$Path == ""}	{
				foreach i {1 2 3 4 5 6 7 8 9 0}	{
						if {[lindex $::opensave::cfg::settings(XQuickdial$i) 0] == $Name}	{
							set Path [lindex $::opensave::cfg::settings(XQuickdial$i) 1]
							break;
						}
				}
			}
			set _labeltext2 "That name is taken.\nYou already have bookmark \"$Name\" pointing to the path:\n$Path"
			set _labeltext3 "Do you want to delete the old bookmark\nand have the name \"$Name\" point to the new path?"
			set _labeltext4 "Yes? Type \"YES\" in all capital letters above to confirm it \nand press Enter/OK to go ahead.\nNo? Press Esc/Cancel to forget about it."
		}
		if {$WhatExists == "path"}	{
			set _pathlindex [lsearch -exact $::opensave::cfg::settings(XGenericBookmarks) $Path]
			incr _pathlindex -1
			set Name [lindex $::opensave::cfg::settings(XGenericBookmarks) $_pathlindex]
			if {$Name == ""}	{
				foreach i {1 2 3 4 5 6 7 8 9 0}	{
						if {[lindex $::opensave::cfg::settings(XQuickdial$i) 1] == $Path}	{
							set Name [lindex $::opensave::cfg::settings(XQuickdial$i) 0]
							break;
						}
				}
			}
			set _labeltext2 "You want to bookmark\n$Path\nThat path is bookmarked already.\nYou have bookmark \"$Name\" pointing to that same path.\nWhat should we do?"
			set _labeltext3 "Choose another name for the new bookmark\nand have multiple bookmarks point to the same path?  "
			set _labeltext4 "Yes? Type in the new name above \nand press Enter/OK to go ahead.\nNo? Press Esc/Cancel to forget about it."
		}
		if {$WhatExists == "both"}	{
			set _pathlindex [lsearch -exact $::opensave::cfg::settings(XGenericBookmarks) $Path]
			incr _pathlindex -1
			set Name [lindex $::opensave::cfg::settings(XGenericBookmarks) $_pathlindex]
			set _namelindex [lsearch -exact $::opensave::cfg::settings(XGenericBookmarks) $Name]
			incr _namelindex
			set Path [lindex $::opensave::cfg::settings(XGenericBookmarks) $_namelindex]

			set _labeltext2 "You are trying to create\na bookmark named \"$Name\" pointing to\n$Path"
			set _labeltext3 "But you already have that exact same\nname and path combination."
			set _labeltext4 "Press either button to close this notice.\nNothing will be done."
		}

		frame $::opensave::existing.outerframe
		$::opensave::existing.outerframe configure -background $::opensave::cfg::settings(HeaderBg)
		$::opensave::existing.outerframe configure -padx 20 -pady 10
		$::opensave::existing.outerframe configure -relief raised -borderwidth 4
		pack $::opensave::existing.outerframe

		frame $::opensave::existing.outerframe.spacer1
		$::opensave::existing.outerframe.spacer1 configure -background $::opensave::cfg::settings(HeaderBg)
		$::opensave::existing.outerframe.spacer1 configure -height 8 -width 600
		pack $::opensave::existing.outerframe.spacer1 -fill both -expand 1

		frame $::opensave::existing.outerframe.frame1_title
		$::opensave::existing.outerframe.frame1_title configure -background #ffffff
		$::opensave::existing.outerframe.frame1_title configure -height 80 -width 600
		$::opensave::existing.outerframe.frame1_title configure -relief solid -borderwidth 1
		pack $::opensave::existing.outerframe.frame1_title -fill both -expand 1
		label $::opensave::existing.outerframe.frame1_title.title1
		$::opensave::existing.outerframe.frame1_title.title1 configure -text "" -justify center
		$::opensave::existing.outerframe.frame1_title.title1 configure -font {Arial 18}
		$::opensave::existing.outerframe.frame1_title.title1 configure -background #ffffff
		pack $::opensave::existing.outerframe.frame1_title.title1
		$::opensave::existing.outerframe.frame1_title.title1 configure -image [image create photo -file /xhome/xxxx/tcl/neweditor/icons/others/infosign.png]

		label $::opensave::existing.outerframe.frame1_title.title2
		$::opensave::existing.outerframe.frame1_title.title2 configure -text "OOPS!" -justify center
		$::opensave::existing.outerframe.frame1_title.title2 configure -font {Arial 18}
		$::opensave::existing.outerframe.frame1_title.title2 configure -background #ffffff
		pack $::opensave::existing.outerframe.frame1_title.title2


		frame $::opensave::existing.outerframe.spacer2
		$::opensave::existing.outerframe.spacer2 configure -background $::opensave::cfg::settings(HeaderBg)
		$::opensave::existing.outerframe.spacer2 configure -height 8 -width 600
		pack $::opensave::existing.outerframe.spacer2 -fill both -expand 1


		frame $::opensave::existing.outerframe.frame2_path
		$::opensave::existing.outerframe.frame2_path configure -background #ffffff
		$::opensave::existing.outerframe.frame2_path configure -height 80 -width 600
		$::opensave::existing.outerframe.frame2_path configure -relief solid -borderwidth 1
		pack $::opensave::existing.outerframe.frame2_path -fill both -expand 1
		label $::opensave::existing.outerframe.frame2_path.path
		$::opensave::existing.outerframe.frame2_path.path configure -background #ffffff
		$::opensave::existing.outerframe.frame2_path.path configure -text $_labeltext2
		$::opensave::existing.outerframe.frame2_path.path configure -justify center
		$::opensave::existing.outerframe.frame2_path.path configure -font {Arial 16}
		pack $::opensave::existing.outerframe.frame2_path.path


		frame $::opensave::existing.outerframe.spacer3
		$::opensave::existing.outerframe.spacer3 configure -background $::opensave::cfg::settings(HeaderBg)
		$::opensave::existing.outerframe.spacer3 configure -height 8 -width 600
		pack $::opensave::existing.outerframe.spacer3 -fill both -expand 1


		frame $::opensave::existing.outerframe.frame3_whatname
		$::opensave::existing.outerframe.frame3_whatname configure -background #ffffff
		$::opensave::existing.outerframe.frame3_whatname configure -height 80 -width 600
		$::opensave::existing.outerframe.frame3_whatname configure -relief solid -borderwidth 1
		$::opensave::existing.outerframe.frame3_whatname configure -padx 0 -pady 2
		pack $::opensave::existing.outerframe.frame3_whatname -fill both -expand 1
		label $::opensave::existing.outerframe.frame3_whatname.whatname
		$::opensave::existing.outerframe.frame3_whatname.whatname configure -text $_labeltext3
		$::opensave::existing.outerframe.frame3_whatname.whatname configure -font {Arial 16}
		$::opensave::existing.outerframe.frame3_whatname.whatname configure -background #ffffff -foreground #000000
		pack $::opensave::existing.outerframe.frame3_whatname.whatname -side top

		if {$WhatExists == "name" || $WhatExists == "path"}	{
			entry $::opensave::existing.outerframe.frame3_whatname.entrybox
			$::opensave::existing.outerframe.frame3_whatname.entrybox configure -font {Arial 16}
			$::opensave::existing.outerframe.frame3_whatname.entrybox configure -background #ffffff
			$::opensave::existing.outerframe.frame3_whatname.entrybox configure -width 30
			$::opensave::existing.outerframe.frame3_whatname.entrybox configure -relief solid -borderwidth 1
			pack $::opensave::existing.outerframe.frame3_whatname.entrybox -side bottom
		}

		frame $::opensave::existing.outerframe.spacer4
		$::opensave::existing.outerframe.spacer4 configure -background $::opensave::cfg::settings(HeaderBg)
		$::opensave::existing.outerframe.spacer4 configure -height 8 -width 600
		pack $::opensave::existing.outerframe.spacer4 -fill both -expand 1


		frame $::opensave::existing.outerframe.spacer5
		$::opensave::existing.outerframe.spacer5 configure -background $::opensave::cfg::settings(HeaderBg)
		$::opensave::existing.outerframe.spacer5 configure -height 8 -width 600
		pack $::opensave::existing.outerframe.spacer5 -fill both -expand 1


		frame $::opensave::existing.outerframe.frame4_quickdial
		$::opensave::existing.outerframe.frame4_quickdial configure -background #ffffff
		$::opensave::existing.outerframe.frame4_quickdial configure -height 80 -width 600
		$::opensave::existing.outerframe.frame4_quickdial configure -relief solid -borderwidth 1
		$::opensave::existing.outerframe.frame4_quickdial configure -padx 0 -pady 0
		pack $::opensave::existing.outerframe.frame4_quickdial -fill both -expand 1
		label $::opensave::existing.outerframe.frame4_quickdial.quickdialquestion
		$::opensave::existing.outerframe.frame4_quickdial.quickdialquestion configure -text $_labeltext4
		$::opensave::existing.outerframe.frame4_quickdial.quickdialquestion configure -font {Arial 16}
		$::opensave::existing.outerframe.frame4_quickdial.quickdialquestion configure -background #ffffff
		pack $::opensave::existing.outerframe.frame4_quickdial.quickdialquestion -side top


		frame $::opensave::existing.outerframe.frame7_okcancel
		$::opensave::existing.outerframe.frame7_okcancel configure -background $::opensave::cfg::settings(HeaderBg)
		$::opensave::existing.outerframe.frame7_okcancel configure -relief flat -borderwidth 0
		$::opensave::existing.outerframe.frame7_okcancel configure -padx 0 -pady 10
		pack $::opensave::existing.outerframe.frame7_okcancel -expand 1
		button $::opensave::existing.outerframe.frame7_okcancel.ok
		$::opensave::existing.outerframe.frame7_okcancel.ok configure -text "OK" -justify center
		$::opensave::existing.outerframe.frame7_okcancel.ok configure -font {Arial 16}
		pack $::opensave::existing.outerframe.frame7_okcancel.ok -side left
		button $::opensave::existing.outerframe.frame7_okcancel.cancel
		$::opensave::existing.outerframe.frame7_okcancel.cancel configure -text "Cancel" -justify center
		$::opensave::existing.outerframe.frame7_okcancel.cancel configure -font {Arial 16}
		$::opensave::existing.outerframe.frame7_okcancel.cancel configure -command {exit 0}
		pack $::opensave::existing.outerframe.frame7_okcancel.cancel -side right


		bind $::opensave::existing			<Escape>			{exit 0}
		wm protocol $::opensave::existing	WM_DELETE_WINDOW  	{exit 0}

		if {$WhatExists == "name" || $WhatExists == "path"}	{
			focus $::opensave::existing.outerframe.frame3_whatname.entrybox
			$::opensave::existing.outerframe.frame3_whatname.entrybox insert end " "
		}
	}

	proc ::opensave::cfg::manage::p.EditBookmark {argAction} {

		package require Tk
		package require tile
		ttk::style theme use alt
		wm withdraw .
		eval destroy [winfo children .]
		catch {destroy .existing}
		set ::opensave::existing [toplevel .existing]
		wm resizable $::opensave::existing 1 1
		tk appname "Manage Bookmarks"
		wm title $::opensave::existing "Manage Bookmarks"

		set _labeltext2 "Change the name."
		set _labeltext3 "Change Quickdial."
		set _labeltext4 "Delete the bookmark."

		frame $::opensave::existing.outerframe
		$::opensave::existing.outerframe configure -background $::opensave::cfg::settings(HeaderBg)
		$::opensave::existing.outerframe configure -padx 20 -pady 10
		$::opensave::existing.outerframe configure -relief raised -borderwidth 4
		pack $::opensave::existing.outerframe

		frame $::opensave::existing.outerframe.spacer1
		$::opensave::existing.outerframe.spacer1 configure -background $::opensave::cfg::settings(HeaderBg)
		$::opensave::existing.outerframe.spacer1 configure -height 8 -width 400
		pack $::opensave::existing.outerframe.spacer1 -fill both -expand 1

		frame $::opensave::existing.outerframe.frame1_title
		$::opensave::existing.outerframe.frame1_title configure -background #ffffff
		$::opensave::existing.outerframe.frame1_title configure -height 80 -width 400
		$::opensave::existing.outerframe.frame1_title configure -relief solid -borderwidth 1
		pack $::opensave::existing.outerframe.frame1_title -fill both -expand 1
		label $::opensave::existing.outerframe.frame1_title.title1
		$::opensave::existing.outerframe.frame1_title.title1 configure -font {Arial 18} -width 150
		$::opensave::existing.outerframe.frame1_title.title1 configure -background #ffffff -justify center
		$::opensave::existing.outerframe.frame1_title.title1 configure -image [image create photo -file /xhome/xxxx/tcl/neweditor/icons/others/pencil.png]
		pack $::opensave::existing.outerframe.frame1_title.title1 -side left

		label $::opensave::existing.outerframe.frame1_title.title2
		$::opensave::existing.outerframe.frame1_title.title2 configure -text "   Edit bookmark" -justify right
		$::opensave::existing.outerframe.frame1_title.title2 configure -font {Arial 18}
		$::opensave::existing.outerframe.frame1_title.title2 configure -background #ffffff
		pack $::opensave::existing.outerframe.frame1_title.title2 -side left


		frame $::opensave::existing.outerframe.spacer2
		$::opensave::existing.outerframe.spacer2 configure -background $::opensave::cfg::settings(HeaderBg)
		$::opensave::existing.outerframe.spacer2 configure -height 8 -width 400
		pack $::opensave::existing.outerframe.spacer2 -fill both -expand 1


		frame $::opensave::existing.outerframe.frame2_rename
		$::opensave::existing.outerframe.frame2_rename configure -background #ffffff
		$::opensave::existing.outerframe.frame2_rename configure -height 80 -width 400
		$::opensave::existing.outerframe.frame2_rename configure -relief solid -borderwidth 1
		pack $::opensave::existing.outerframe.frame2_rename -fill both -expand 1
		label $::opensave::existing.outerframe.frame2_rename.path
		$::opensave::existing.outerframe.frame2_rename.path configure -background #ffffff
		$::opensave::existing.outerframe.frame2_rename.path configure -text $_labeltext2
		$::opensave::existing.outerframe.frame2_rename.path configure -justify left
		$::opensave::existing.outerframe.frame2_rename.path configure -font {Arial 16}
		$::opensave::existing.outerframe.frame2_rename.path configure
		pack $::opensave::existing.outerframe.frame2_rename.path -side left

		entry $::opensave::existing.outerframe.frame2_rename.entrybox
		$::opensave::existing.outerframe.frame2_rename.entrybox configure -font {Arial 16}
		$::opensave::existing.outerframe.frame2_rename.entrybox configure -background #ffffff
		$::opensave::existing.outerframe.frame2_rename.entrybox configure -width 15
		$::opensave::existing.outerframe.frame2_rename.entrybox configure -relief solid -borderwidth 1
		pack $::opensave::existing.outerframe.frame2_rename.entrybox -side left -expand 1

		frame $::opensave::existing.outerframe.frame2_rename.buttonsframe
		pack $::opensave::existing.outerframe.frame2_rename.buttonsframe
		button $::opensave::existing.outerframe.frame2_rename.buttonsframe.ok
		$::opensave::existing.outerframe.frame2_rename.buttonsframe.ok configure -text "OK" -justify center
		$::opensave::existing.outerframe.frame2_rename.buttonsframe.ok configure -font {Arial 16}
		pack $::opensave::existing.outerframe.frame2_rename.buttonsframe.ok -side left
		button $::opensave::existing.outerframe.frame2_rename.buttonsframe.cancel
		$::opensave::existing.outerframe.frame2_rename.buttonsframe.cancel configure -text "Cancel" -justify center
		$::opensave::existing.outerframe.frame2_rename.buttonsframe.cancel configure -font {Arial 16}
		$::opensave::existing.outerframe.frame2_rename.buttonsframe.cancel configure -command {exit 0}
		pack $::opensave::existing.outerframe.frame2_rename.buttonsframe.cancel -side left


		frame $::opensave::existing.outerframe.spacer3
		$::opensave::existing.outerframe.spacer3 configure -background $::opensave::cfg::settings(HeaderBg)
		$::opensave::existing.outerframe.spacer3 configure -height 8 -width 400
		pack $::opensave::existing.outerframe.spacer3 -fill both -expand 1


		frame $::opensave::existing.outerframe.frame3_quickdial
		$::opensave::existing.outerframe.frame3_quickdial configure -background #ffffff
		$::opensave::existing.outerframe.frame3_quickdial configure -height 80 -width 400
		$::opensave::existing.outerframe.frame3_quickdial configure -relief solid -borderwidth 1	
		$::opensave::existing.outerframe.frame3_quickdial configure -padx 0 -pady 2
		pack $::opensave::existing.outerframe.frame3_quickdial -fill both -expand 1
		label $::opensave::existing.outerframe.frame3_quickdial.label
		$::opensave::existing.outerframe.frame3_quickdial.label configure -text $_labeltext3
		$::opensave::existing.outerframe.frame3_quickdial.label configure -font {Arial 16}
		$::opensave::existing.outerframe.frame3_quickdial.label configure -background #ffffff -foreground #000000
		pack $::opensave::existing.outerframe.frame3_quickdial.label -side left

		spinbox $::opensave::existing.outerframe.frame3_quickdial.spinbox
		set ::opensave::existing.spinboxlist [list "No change"\
		"Yes, number 0" "Yes, number 9" "Yes, number 8" "Yes, number 7" "Yes, number 9" \
		"Yes, number 5" "Yes, number 4" "Yes, number 3" "Yes, number 2" "Yes, number 1" "No number"]
		$::opensave::existing.outerframe.frame3_quickdial.spinbox configure -values [set ::opensave::existing.spinboxlist] -wrap 1
		$::opensave::existing.outerframe.frame3_quickdial.spinbox configure -readonlybackground #ffffff -selectbackground #ffffff
		$::opensave::existing.outerframe.frame3_quickdial.spinbox configure -font {Arial 16}
		$::opensave::existing.outerframe.frame3_quickdial.spinbox configure -width 14
		$::opensave::existing.outerframe.frame3_quickdial.spinbox configure -relief solid -borderwidth 1
		$::opensave::existing.outerframe.frame3_quickdial.spinbox configure -state readonly
		$::opensave::existing.outerframe.frame3_quickdial.spinbox configure -textvariable ::opensave::existing.outerframe.frame3_quickdial.choice
		pack $::opensave::existing.outerframe.frame3_quickdial.spinbox -side left

		frame $::opensave::existing.outerframe.frame3_quickdial.buttonsframe
		pack $::opensave::existing.outerframe.frame3_quickdial.buttonsframe
		button $::opensave::existing.outerframe.frame3_quickdial.buttonsframe.ok
		$::opensave::existing.outerframe.frame3_quickdial.buttonsframe.ok configure -text "OK" -justify center
		$::opensave::existing.outerframe.frame3_quickdial.buttonsframe.ok configure -font {Arial 16}
		pack $::opensave::existing.outerframe.frame3_quickdial.buttonsframe.ok -side left
		button $::opensave::existing.outerframe.frame3_quickdial.buttonsframe.cancel
		$::opensave::existing.outerframe.frame3_quickdial.buttonsframe.cancel configure -text "Cancel" -justify center
		$::opensave::existing.outerframe.frame3_quickdial.buttonsframe.cancel configure -font {Arial 16}
		$::opensave::existing.outerframe.frame3_quickdial.buttonsframe.cancel configure -command {exit 0}
		pack $::opensave::existing.outerframe.frame3_quickdial.buttonsframe.cancel -side left


		frame $::opensave::existing.outerframe.spacer4
		$::opensave::existing.outerframe.spacer4 configure -background $::opensave::cfg::settings(HeaderBg)
		$::opensave::existing.outerframe.spacer4 configure -height 8 -width 400
		pack $::opensave::existing.outerframe.spacer4 -fill both -expand 1


		frame $::opensave::existing.outerframe.spacer5
		$::opensave::existing.outerframe.spacer5 configure -background $::opensave::cfg::settings(HeaderBg)
		$::opensave::existing.outerframe.spacer5 configure -height 8 -width 400
		pack $::opensave::existing.outerframe.spacer5 -fill both -expand 1


		frame $::opensave::existing.outerframe.frame4_delete
		$::opensave::existing.outerframe.frame4_delete configure -background #ffffff
		$::opensave::existing.outerframe.frame4_delete configure -height 80 -width 400
		$::opensave::existing.outerframe.frame4_delete configure -relief solid -borderwidth 1
		$::opensave::existing.outerframe.frame4_delete configure -padx 0 -pady 0
		pack $::opensave::existing.outerframe.frame4_delete -fill both -expand 1
		label $::opensave::existing.outerframe.frame4_delete.quickdialquestion
		$::opensave::existing.outerframe.frame4_delete.quickdialquestion configure -text $_labeltext4
		$::opensave::existing.outerframe.frame4_delete.quickdialquestion configure -font {Arial 16}
		$::opensave::existing.outerframe.frame4_delete.quickdialquestion configure -background #ffffff
		pack $::opensave::existing.outerframe.frame4_delete.quickdialquestion -side left

		frame $::opensave::existing.outerframe.frame4_delete.buttons
		$::opensave::existing.outerframe.frame4_delete.buttons configure -background #ffffff
		$::opensave::existing.outerframe.frame4_delete.buttons configure -relief flat -borderwidth 0
		$::opensave::existing.outerframe.frame4_delete.buttons configure -padx 0 -pady 10
		pack $::opensave::existing.outerframe.frame4_delete.buttons -expand 1
		button $::opensave::existing.outerframe.frame4_delete.buttons.ok
		$::opensave::existing.outerframe.frame4_delete.buttons.ok configure -text "Delete" -justify center
		$::opensave::existing.outerframe.frame4_delete.buttons.ok configure -font {Arial 16}
		pack $::opensave::existing.outerframe.frame4_delete.buttons.ok -side left
		button $::opensave::existing.outerframe.frame4_delete.buttons.cancel
		$::opensave::existing.outerframe.frame4_delete.buttons.cancel configure -text "Cancel" -justify center
		$::opensave::existing.outerframe.frame4_delete.buttons.cancel configure -font {Arial 16}
		$::opensave::existing.outerframe.frame4_delete.buttons.cancel configure -command {exit 0}
		pack $::opensave::existing.outerframe.frame4_delete.buttons.cancel -side right


		bind $::opensave::existing			<Escape>			{exit 0}
		wm protocol $::opensave::existing	WM_DELETE_WINDOW  	{exit 0}

		focus $::opensave::existing.outerframe.frame2_rename.entrybox
		$::opensave::existing.outerframe.frame2_rename.entrybox insert end " "
	}

	proc ::opensave::cfg::manage::p.AddBookmarkProc	{argPath}	{

		set NewBookmarkName [string trim [$::opensave::manage.outerframe.frame3_whatname.entrybox get]]
		set NewBookmarkPath [string trim $argPath]
		set Quickdial [set ::opensave::manage.outerframe.frame4_quickdial.choice]

		#check if name is empty
		if {$NewBookmarkName == ""}	{
			::opensave::cfg::manage::p.AddBookmarkWidget $NewBookmarkPath
			return
		}

		#check if bookmark already exists
		set _ExistList {"" "" ""}
		if {[info exists ::opensave::cfg::settings(XGenericBookmarks)] && [llength $::opensave::cfg::settings(XGenericBookmarks)] > 0}	{
			for {set i 0} {$i < [llength $::opensave::cfg::settings(XGenericBookmarks)]} {incr i} {
				if {[lindex $::opensave::cfg::settings(XGenericBookmarks) $i] == $NewBookmarkName}	{
					set _ExistList [lreplace $_ExistList 0 0 $NewBookmarkName]
				}
				incr i
				if {[lindex $::opensave::cfg::settings(XGenericBookmarks) $i] == $NewBookmarkPath}	{
					set _ExistList [lreplace $_ExistList 1 1 $NewBookmarkPath]
				}
			}
		}
		if {[lindex $_ExistList 0] == "" && [lindex $_ExistList 1] == ""}	{
			foreach i {1 2 3 4 5 6 7 8 9 0}	{
				if {[info exists ::opensave::cfg::settings(XQuickdial$i)]}	{
					if {[lindex $::opensave::cfg::settings(XQuickdial$i) 0] == $NewBookmarkName}	{
						set _ExistList [lreplace $_ExistList 0 0 $NewBookmarkName]
						break;
					}
					if {[lindex $::opensave::cfg::settings(XQuickdial$i) 1] == $NewBookmarkPath}	{
						set _ExistList [lreplace $_ExistList 1 1 $NewBookmarkPath]
						break;
					}
				}
			}
		}
		if {[info exists ::opensave::cfg::settings(XQuickdial$Quickdial)]}	{
			set _ExistList [lreplace $_ExistList 2 2 $Quickdial]
		}

		if {[lindex $_ExistList 0] != "" || [lindex $_ExistList 1] != "" || [lindex $_ExistList 2] != ""}	{
			::opensave::cfg::manage::p.BookmarkExists $_ExistList
			return
		}


		# -------- add new generic bookmark --------
		if {$Quickdial == "No"}	{
			lappend ::opensave::cfg::settings(XGenericBookmarks) $NewBookmarkName $NewBookmarkPath
		}
		# -------- add new quickdial bookmark --------
		set quickdialnumber [string range $Quickdial end end]
		if {[string is integer [string range $quickdialnumber end end]]}	{
			set ::opensave::cfg::settings(XQuickdial$quickdialnumber) [list $NewBookmarkName $NewBookmarkPath]
		}
		# -------- insert new entries into widget --------
		set bookmarkentries ""
		
		# collect Quickdial entry names
		set quickdialentries ""
		foreach k [lsort [array names ::opensave::cfg::settings]]	{
			if {[string range $k 0 9] == "XQuickdial"}	{
				lappend bookmarkentries "[string range $k 10 10] - [lindex $::opensave::cfg::settings($k) 0]"
			}
		}
		# collect generic bookmark entry names
		for {set i 0} {$i < [llength $::opensave::cfg::settings(XGenericBookmarks)]} {incr i} {
			lappend bookmarkentries "[lindex $::opensave::cfg::settings(XGenericBookmarks) $i]"
			incr i
		}

		# insert all entries into widget
		$::opensave::bookmarks configure -state normal
		$::opensave::bookmarks delete 1.0 end
		if {[llength $bookmarkentries] > 0}	{
			for {set i 0} {$i < [llength $bookmarkentries]} {incr i} {
				$::opensave::bookmarks insert end [lindex $bookmarkentries $i]
				if {$i != [expr [llength $bookmarkentries] - 1]}	{
					$::opensave::bookmarks insert end "\n"
				}
			}
		}
		$::opensave::bookmarks configure -state disabled

		# update config file
		file delete $::opensave::CONFIGFILE
		set _fp [open $::opensave::CONFIGFILE w]
		foreach _item [lsort [array names ::opensave::cfg::settings]]	{
			puts $_fp "$_item = $::opensave::cfg::settings($_item)"
		}
		close $_fp

		catch {destroy .manage}
		return
	}

	proc ::opensave::cfg::manage::p.AddBookmarkWidget	{}	{
		
		set argPath $::opensave::SELECTEDFILE

		catch {destroy .manage}
		set ::opensave::manage [toplevel .manage]
		wm resizable $::opensave::manage 1 1
		tk appname "Manage Bookmarks"
		wm title $::opensave::manage "Manage Bookmarks"

		frame $::opensave::manage.outerframe
		$::opensave::manage.outerframe configure -background $::opensave::cfg::settings(HeaderBg)
		$::opensave::manage.outerframe configure -padx 20 -pady 10
		$::opensave::manage.outerframe configure -relief raised -borderwidth 4
		pack $::opensave::manage.outerframe

		frame $::opensave::manage.outerframe.spacer1
		$::opensave::manage.outerframe.spacer1 configure -background $::opensave::cfg::settings(HeaderBg)
		$::opensave::manage.outerframe.spacer1 configure -height 8 -width 600
		pack $::opensave::manage.outerframe.spacer1 -fill both -expand 1

		frame $::opensave::manage.outerframe.frame1_title
		$::opensave::manage.outerframe.frame1_title configure -background #ffffff
		$::opensave::manage.outerframe.frame1_title configure -height 80 -width 600
		$::opensave::manage.outerframe.frame1_title configure -relief solid -borderwidth 1
		pack $::opensave::manage.outerframe.frame1_title -fill both -expand 1
		label $::opensave::manage.outerframe.frame1_title.title
		$::opensave::manage.outerframe.frame1_title.title configure -text "ADD BOOKMARK" -justify center
		$::opensave::manage.outerframe.frame1_title.title configure -font {Arial 18}
		$::opensave::manage.outerframe.frame1_title.title configure -background #ffffff
		pack $::opensave::manage.outerframe.frame1_title.title


		frame $::opensave::manage.outerframe.spacer2
		$::opensave::manage.outerframe.spacer2 configure -background $::opensave::cfg::settings(HeaderBg)
		$::opensave::manage.outerframe.spacer2 configure -height 8 -width 600
		pack $::opensave::manage.outerframe.spacer2 -fill both -expand 1


		frame $::opensave::manage.outerframe.frame2_path
		$::opensave::manage.outerframe.frame2_path configure -background #ffffff
		$::opensave::manage.outerframe.frame2_path configure -height 80 -width 600
		$::opensave::manage.outerframe.frame2_path configure -relief solid -borderwidth 1
		pack $::opensave::manage.outerframe.frame2_path -fill both -expand 1
		label $::opensave::manage.outerframe.frame2_path.path
		$::opensave::manage.outerframe.frame2_path.path configure -background #ffffff
		$::opensave::manage.outerframe.frame2_path.path configure -text $argPath
		$::opensave::manage.outerframe.frame2_path.path configure -font {Arial 16}
		pack $::opensave::manage.outerframe.frame2_path.path -side left


		frame $::opensave::manage.outerframe.spacer3
		$::opensave::manage.outerframe.spacer3 configure -background $::opensave::cfg::settings(HeaderBg)
		$::opensave::manage.outerframe.spacer3 configure -height 8 -width 600
		pack $::opensave::manage.outerframe.spacer3 -fill both -expand 1


		frame $::opensave::manage.outerframe.frame3_whatname
		$::opensave::manage.outerframe.frame3_whatname configure -background #ffffff
		$::opensave::manage.outerframe.frame3_whatname configure -height 80 -width 600
		$::opensave::manage.outerframe.frame3_whatname configure -relief solid -borderwidth 1
		$::opensave::manage.outerframe.frame3_whatname configure -padx 0 -pady 2
		pack $::opensave::manage.outerframe.frame3_whatname -fill both -expand 1
		label $::opensave::manage.outerframe.frame3_whatname.whatname
		$::opensave::manage.outerframe.frame3_whatname.whatname configure -text "What name?  "
		$::opensave::manage.outerframe.frame3_whatname.whatname configure -font {Arial 16}
		$::opensave::manage.outerframe.frame3_whatname.whatname configure -background #ffffff -foreground #000000
		pack $::opensave::manage.outerframe.frame3_whatname.whatname -side left
		entry $::opensave::manage.outerframe.frame3_whatname.entrybox
		$::opensave::manage.outerframe.frame3_whatname.entrybox configure -font {Arial 16}
		$::opensave::manage.outerframe.frame3_whatname.entrybox configure -background #ffffff
		$::opensave::manage.outerframe.frame3_whatname.entrybox configure -width 30
		$::opensave::manage.outerframe.frame3_whatname.entrybox configure -relief solid -borderwidth 1
		$::opensave::manage.outerframe.frame3_whatname.entrybox configure -textvariable ::opensave::manage.outerframe.frame3_whatname.entrybox.name
		pack $::opensave::manage.outerframe.frame3_whatname.entrybox -side bottom


		frame $::opensave::manage.outerframe.spacer4
		$::opensave::manage.outerframe.spacer4 configure -background $::opensave::cfg::settings(HeaderBg)
		$::opensave::manage.outerframe.spacer4 configure -height 8 -width 600
		pack $::opensave::manage.outerframe.spacer4 -fill both -expand 1


		frame $::opensave::manage.outerframe.spacer5
		$::opensave::manage.outerframe.spacer5 configure -background $::opensave::cfg::settings(HeaderBg)
		$::opensave::manage.outerframe.spacer5 configure -height 8 -width 600
		pack $::opensave::manage.outerframe.spacer5 -fill both -expand 1


		frame $::opensave::manage.outerframe.frame4_quickdial
		$::opensave::manage.outerframe.frame4_quickdial configure -background #ffffff
		$::opensave::manage.outerframe.frame4_quickdial configure -height 80 -width 600
		$::opensave::manage.outerframe.frame4_quickdial configure -relief solid -borderwidth 1
		$::opensave::manage.outerframe.frame4_quickdial configure -padx 0 -pady 0
		pack $::opensave::manage.outerframe.frame4_quickdial -fill both -expand 1
		label $::opensave::manage.outerframe.frame4_quickdial.quickdialquestion
		$::opensave::manage.outerframe.frame4_quickdial.quickdialquestion configure -text "Quick dial?    "
		$::opensave::manage.outerframe.frame4_quickdial.quickdialquestion configure -font {Arial 16}
		$::opensave::manage.outerframe.frame4_quickdial.quickdialquestion configure -background #ffffff
		pack $::opensave::manage.outerframe.frame4_quickdial.quickdialquestion -side left


		spinbox $::opensave::manage.outerframe.frame4_quickdial.spinbox
		set ::opensave::manage.spinboxlist [list "No" \
		"Yes, number 0" "Yes, number 9" "Yes, number 8" "Yes, number 7" "Yes, number 9" \
		"Yes, number 5" "Yes, number 4" "Yes, number 3" "Yes, number 2" "Yes, number 1"]
		$::opensave::manage.outerframe.frame4_quickdial.spinbox configure -values [set ::opensave::manage.spinboxlist] -wrap 1
		$::opensave::manage.outerframe.frame4_quickdial.spinbox configure -readonlybackground #ffffff -selectbackground #ffffff
		$::opensave::manage.outerframe.frame4_quickdial.spinbox configure -font {Arial 16}
		$::opensave::manage.outerframe.frame4_quickdial.spinbox configure -width 14
		$::opensave::manage.outerframe.frame4_quickdial.spinbox configure -state readonly
		$::opensave::manage.outerframe.frame4_quickdial.spinbox configure -textvariable ::opensave::manage.outerframe.frame4_quickdial.choice
		pack $::opensave::manage.outerframe.frame4_quickdial.spinbox -side bottom


		frame $::opensave::manage.outerframe.frame7_okcancel
		$::opensave::manage.outerframe.frame7_okcancel configure -background $::opensave::cfg::settings(HeaderBg)
		$::opensave::manage.outerframe.frame7_okcancel configure -relief flat -borderwidth 0
		$::opensave::manage.outerframe.frame7_okcancel configure -padx 0 -pady 10
		pack $::opensave::manage.outerframe.frame7_okcancel -expand 1
		button $::opensave::manage.outerframe.frame7_okcancel.ok
		$::opensave::manage.outerframe.frame7_okcancel.ok configure -text "OK" -justify center
		$::opensave::manage.outerframe.frame7_okcancel.ok configure -font {Arial 16}
		pack $::opensave::manage.outerframe.frame7_okcancel.ok -side left
		button $::opensave::manage.outerframe.frame7_okcancel.cancel
		$::opensave::manage.outerframe.frame7_okcancel.cancel configure -text "Cancel" -justify center
		$::opensave::manage.outerframe.frame7_okcancel.cancel configure -font {Arial 16}
		$::opensave::manage.outerframe.frame7_okcancel.cancel configure -command {exit 0}
		pack $::opensave::manage.outerframe.frame7_okcancel.cancel -side right

		bind $::opensave::manage 			<Return>			"::opensave::cfg::manage::p.AddBookmarkProc [list $argPath]"
		
		bind $::opensave::manage			<Escape>			{catch {destroy .manage}}
		wm protocol $::opensave::manage		WM_DELETE_WINDOW  	{catch {destroy .manage}}

		focus $::opensave::manage.outerframe.frame3_whatname.entrybox
		$::opensave::manage.outerframe.frame3_whatname.entrybox insert end " "

	}


	proc ::opensave::p.Update.Widgets.On.Any.Action  {args}  	{ 
	# ----------------------------------------------------------------
	# Any move of the mouse or keyboard causes all things to be updated

		set ::opensave::WidgetThatHasFocusNow [focus]

		if	{[string length $::opensave::WidgetThatHasFocusNow] <= 0}	{return}
		catch {set ::opensave::currindex [$::opensave::WidgetThatHasFocusNow index insert]}
		lassign [split $::opensave::currindex "."] ::opensave::CURRLINE ::opensave::CURRCOL
		$::opensave::statusbar configure -text "Line: $::opensave::CURRLINE  Col: $::opensave::CURRCOL"
		
		# focus on FileListColumn ------------------------
		if {$::opensave::WidgetThatHasFocusNow == $::opensave::FileListColumn}	{
			$::opensave::pathline selection clear
			::opensave::p.fixWidth
			
			$::opensave::FileListColumn 	tag remove 	"sel" 1.0 end

			$::opensave::FileListColumn 	tag remove 	"selected" $::opensave::PreviouslySelectedLine.0 "$::opensave::PreviouslySelectedLine.0 display lineend +1c"
			$::opensave::FileListColumn 	tag add 	"selected" $::opensave::CURRLINE.2 "$::opensave::CURRLINE.0 display lineend +1c"
			$::opensave::SizeColumn 		tag remove 	"selected" $::opensave::PreviouslySelectedLine.0 "$::opensave::PreviouslySelectedLine.0 display lineend +1c"
			$::opensave::DateColumn 		tag remove 	"selected" $::opensave::PreviouslySelectedLine.0 "$::opensave::PreviouslySelectedLine.0 display lineend +1c"
			$::opensave::PermissionColumn	tag remove 	"selected" $::opensave::PreviouslySelectedLine.0 "$::opensave::PreviouslySelectedLine.0 display lineend +1c"
			$::opensave::OwnerColumn 		tag remove 	"selected" $::opensave::PreviouslySelectedLine.0 "$::opensave::PreviouslySelectedLine.0 display lineend +1c"

			if {$::opensave::CURRLINE != 1}	{
				$::opensave::SizeColumn 		tag add 	"selected" $::opensave::CURRLINE.1 "$::opensave::CURRLINE.0 display lineend +1c"
				$::opensave::DateColumn 		tag add 	"selected" $::opensave::CURRLINE.1 "$::opensave::CURRLINE.0 display lineend +1c"
				$::opensave::PermissionColumn	tag add 	"selected" $::opensave::CURRLINE.1 "$::opensave::CURRLINE.0 display lineend +1c"
				$::opensave::OwnerColumn 		tag add 	"selected" $::opensave::CURRLINE.1 "$::opensave::CURRLINE.0 display lineend +1c"
			}

			if {$::opensave::WidgetThatHasFocusNow == $::opensave::FileListColumn}	{
				$::opensave::bookmarks tag remove "selected" 1.0 end
			}
			if {$::opensave::WidgetThatHasFocusNow == $::opensave::pathline}	{
				$::opensave::bookmarks tag remove "selected" 1.0 end
			}

			$::opensave::w.outer.statusbar configure -text "$::opensave::FILECOUNT files, $::opensave::DIRCOUNT subdirs, $::opensave::ITEMSUM items, $::opensave::FILESIZESUM total."
			if {$::opensave::WidgetThatHasFocusNow == $::opensave::FileListColumn}	{
				set ::opensave::SELECTEDFILE [file join $::opensave::CURRENTDIR [$::opensave::FileListColumn get -displaychars $::opensave::CURRLINE.2 "$::opensave::CURRLINE.0 lineend"]]
				if {[file tail $::opensave::SELECTEDFILE] == "---" && [file exists $::opensave::SELECTEDFILE] == 0}	{
					set ::opensave::SELECTEDFILE [file dirname $::opensave::SELECTEDFILE]
				}
			}
			if {[info exists opensave::SELECTEDFILE] && [file tail $::opensave::SELECTEDFILE] == ".."}	{
				set ::opensave::SELECTEDFILE $::opensave::CURRENTDIR
			}
			$::opensave::pathline configure -textvariable ::opensave::SELECTEDFILE

			set ::opensave::PreviouslySelectedLine $::opensave::CURRLINE
		}
		# focus on pathline ------------------------------
		if {$::opensave::WidgetThatHasFocusNow == $::opensave::pathline}	{
			$::opensave::pathline selection clear
			$::opensave::FileListColumn 	tag remove 	"sel" 1.0 end
		}
		# focus on bookmarks ----------------------------
		if {$::opensave::WidgetThatHasFocusNow == $::opensave::bookmarks}	{
			$::opensave::pathline selection clear
			$::opensave::FileListColumn tag remove "sel" 1.0 end
			#$::opensave::FileListColumn tag remove "selected" 1.0 end

			$::opensave::bookmarks tag remove "selected" 1.0 end
			set ::opensave::currindex [$::opensave::bookmarks index insert]
			lassign [split $::opensave::currindex "."] ::opensave::bookmarkline ::opensave::bookmarkcol
			$::opensave::bookmarks mark set selected "$::opensave::bookmarkline.0 lineend"
			$::opensave::bookmarks tag add "selected" $::opensave::bookmarkline.0 "$::opensave::bookmarkline.0 lineend +1c"
			$::opensave::bookmarks configure -state disabled
		}

		# ----------------------------------------------------------------
		# DISPLAY DATA AT THE TOP AS A DEBUG TOOL
		# TO BE REMOVED BEFORE PUBLISHING
		if  {$::opensave::cfg::debug}  { 
			if {[focus] == $::opensave::FileListColumn}	{
				$::opensave::topview delete 1.0 end
				$::opensave::topview.topleft2.opensavelabel configure -state normal
				$::opensave::topview.topleft2.opensavelabel delete 1.0 end
				set selectedentry [$::opensave::FileListColumn get -displaychars $::opensave::CURRLINE.2 "$::opensave::CURRLINE.2 lineend"]
				set selectedentry [file join $::opensave::CURRENTDIR [string trim $selectedentry]]

				if {$selectedentry == "$::opensave::CURRENTDIR/.."}	{
					$::opensave::topview.topleft2.opensavelabel insert end " "
					::opensave::p.InsertCorrectIcon $::opensave::topview.topleft2.opensavelabel $selectedentry
					$::opensave::topview.topleft2.opensavelabel insert end "  [file tail $::opensave::CURRENTDIR]\n"
					$::opensave::topview.topleft2.opensavelabel insert end "       the current directory"
					$::opensave::topview.topleft2.opensavelabel configure -state disabled
					return
				}

				if {[file exists $selectedentry]}	{
					$::opensave::topview.topleft2.opensavelabel insert end " "
					::opensave::p.InsertCorrectIcon $::opensave::topview.topleft2.opensavelabel $selectedentry
					$::opensave::topview.topleft2.opensavelabel insert end "  [file tail $selectedentry]\n"
					$::opensave::topview.topleft2.opensavelabel insert end "       type: [file type $selectedentry]"
					if {[file type $selectedentry] == "link"}	{
						$::opensave::topview.topleft2.opensavelabel insert end " to [file type [file readlink $selectedentry]]\n"
						$::opensave::topview.topleft2.opensavelabel insert end "       points to: [file readlink $selectedentry]"
						if {[file type [file readlink $selectedentry]] == "link"}	{
							$::opensave::topview.topleft2.opensavelabel insert end "\n       which points to: [file readlink $selectedentry]"
						}
						$::opensave::topview.topleft2.opensavelabel configure -state disabled
					} else {
						$::opensave::topview.topleft2.opensavelabel insert end "\n"
						$::opensave::topview.topleft2.opensavelabel configure -state disabled
					}
				}
			}
		}
	}


	proc ::opensave::p.RunFunction {argAction}	{

		if {$argAction == "open"}	{
			::opensave::p.ClearAllColumns
			
			if {[file isdirectory $::opensave::CURRENTDIR]}	{
				cd $::opensave::CURRENTDIR
			} else {cd [file dirname $::opensave::CURRENTDIR]}

			set _filelist ""

			if {[info exists ::opensave::usingfilter]}	{
				unset ::opensave::usingfilter

				if {[file isdirectory $::opensave::CURRENTDIR]}	{
				
					if {$::tcl_platform(platform) == "unix"}	{
						set _filelist [glob -types {b c d f l p s} -nocomplain -tails -directory $::opensave::CURRENTDIR *]
					}
					if {$::tcl_platform(platform) == "unix" && $::opensave::cfg::settings(HiddenFiles) == "show"}	{
						foreach i [glob -types hidden -nocomplain -tails -directory $::opensave::CURRENTDIR *] {
							lappend _filelist $i
						}
					}
				} else {

					if {$::tcl_platform(platform) == "unix"}	{
						puts [list [file dirname $::opensave::CURRENTDIR] [file tail $::opensave::CURRENTDIR]]
						set _filelist [glob -types {b c d f l p s} -nocomplain -tails -path [file dirname $::opensave::CURRENTDIR]/ [file tail $::opensave::CURRENTDIR]]
					}
					if {$::tcl_platform(platform) == "unix" && $::opensave::cfg::settings(HiddenFiles) == "show"}	{
						foreach i [glob -types hidden -nocomplain -tails -path [file dirname $::opensave::CURRENTDIR]/ [file tail $::opensave::CURRENTDIR]] {
							lappend _filelist $i
						}
					}
					set ::opensave::CURRENTDIR [file dirname $::opensave::CURRENTDIR]
				}

			} else {

				# Windows not contemplated yet. Stay tuned for a future version.
				if {$::tcl_platform(platform) == "unix"}	{
					set _filelist [glob -types {b c d f l p s} -nocomplain -tails -directory $::opensave::CURRENTDIR *]
				}
				if {$::tcl_platform(platform) == "unix" && $::opensave::cfg::settings(HiddenFiles) == "show"}	{
					foreach i [glob -types hidden -nocomplain -tails -directory $::opensave::CURRENTDIR *] {
						lappend _filelist $i
					}
				}
			}
			
			set _filelistdirs ""
			set _filelistfiles ""
			foreach _f $_filelist {
				if {[file isdir $_f] && $_f != ".." && $_f != "."}	{lappend _filelistdirs $_f}
			}
			foreach _f $_filelist {
				if {[file isfile $_f]}	{lappend _filelistfiles $_f}
			}
			
			set ::opensave::DIRCOUNT 0
			set ::opensave::FILECOUNT 0
			set ::opensave::FILESIZESUM 0
			foreach _f $_filelistdirs {set ::opensave::DIRCOUNT [incr ::opensave::DIRCOUNT]}
			foreach _f $_filelistfiles {
				set ::opensave::FILECOUNT [incr ::opensave::FILECOUNT]
				set ::opensave::FILESIZESUM	[expr {$::opensave::FILESIZESUM + [file size $_f]}]
			}
			set ::opensave::ITEMSUM 		[expr {$::opensave::FILECOUNT + $::opensave::DIRCOUNT}]
			set ::opensave::FILESIZESUM 	[::opensave::p.FormatUnits $::opensave::FILESIZESUM]
			
			foreach _f $_filelistdirs {
				lappend _filelistdirmap [list $_f [file size $_f] [file mtime $_f] \
					[file attributes $_f -permissions] [file attributes $_f -owner] \
					[file attributes $_f -group]]
			}

			foreach _f $_filelistfiles {
				lappend _filelistfilemap [list $_f [file size $_f] [file mtime $_f] \
					[file attributes $_f -permissions] [file attributes $_f -owner] \
					[file attributes $_f -group]]
			}
			
			



			$::opensave::FileListColumn configure -bg $::opensave::cfg::TextBg
			$::opensave::SizeColumn configure -bg $::opensave::cfg::TextBg
			$::opensave::DateColumn configure -bg $::opensave::cfg::TextBg
			$::opensave::PermissionColumn configure -bg $::opensave::cfg::TextBg
			$::opensave::OwnerColumn configure -bg $::opensave::cfg::TextBg

			if {$::opensave::cfg::settings(Sorting1) == "alpha"}	{
				$::opensave::FileListColumn configure -background $::opensave::cfg::settings(SortedColumnBg)
				$::opensave::FileListColumn configure -foreground $::opensave::cfg::settings(SortedColumnFg)
				if {$::opensave::cfg::settings(Sorting2) == "increase"}	{
					if {[info exists _filelistdirmap]}	{set _filelistdirmap   [lsort -dictionary -index 0 $_filelistdirmap]}
					if {[info exists _filelistfilemap]}	{set _filelistfilemap  [lsort -dictionary -index 0 $_filelistfilemap]}
				}
				if {$::opensave::cfg::settings(Sorting2) == "decrease"}	{
					if {[info exists _filelistdirmap]}	{set _filelistdirmap   [lsort -dictionary -decreasing -index 0 $_filelistdirmap]}
					if {[info exists _filelistfilemap]}	{set _filelistfilemap  [lsort -dictionary -decreasing -index 0 $_filelistfilemap]}
				}
			}
			if {$::opensave::cfg::settings(Sorting1) == "size"}	{
				$::opensave::SizeColumn configure -background $::opensave::cfg::settings(SortedColumnBg)
				$::opensave::SizeColumn configure -foreground $::opensave::cfg::settings(SortedColumnFg)
				if {$::opensave::cfg::settings(Sorting2) == "increase"}	{
					if {[info exists _filelistdirmap]}	{set _filelistdirmap   [lsort -integer -index 1 $_filelistdirmap]}
					if {[info exists _filelistfilemap]}	{set _filelistfilemap  [lsort -integer -index 1 $_filelistfilemap]}
				}
				if {$::opensave::cfg::settings(Sorting2) == "decrease"}	{
					if {[info exists _filelistdirmap]}	{set _filelistdirmap   [lsort -integer -decreasing -index 1 $_filelistdirmap]}
					if {[info exists _filelistfilemap]}	{set _filelistfilemap  [lsort -integer -decreasing -index 1 $_filelistfilemap]}
				}
			}
			if {$::opensave::cfg::settings(Sorting1) == "date"}	{
				$::opensave::DateColumn configure -background $::opensave::cfg::settings(SortedColumnBg)
				$::opensave::DateColumn configure -foreground $::opensave::cfg::settings(SortedColumnFg)
				if {$::opensave::cfg::settings(Sorting2) == "increase"}	{
					if {[info exists _filelistdirmap]}	{set _filelistdirmap   [lsort -integer -index 2 $_filelistdirmap]}
					if {[info exists _filelistfilemap]}	{set _filelistfilemap  [lsort -integer -index 2 $_filelistfilemap]}
				}
				if {$::opensave::cfg::settings(Sorting2) == "decrease"}	{
					if {[info exists _filelistdirmap]}	{set _filelistdirmap   [lsort -integer -decreasing -index 2 $_filelistdirmap]}
					if {[info exists _filelistfilemap]}	{set _filelistfilemap  [lsort -integer -decreasing -index 2 $_filelistfilemap]}
				}
			}
			if {$::opensave::cfg::settings(Sorting1) == "perm"}	{
				$::opensave::PermissionColumn configure -background $::opensave::cfg::settings(SortedColumnBg)
				$::opensave::PermissionColumn configure -foreground $::opensave::cfg::settings(SortedColumnFg)
				if {$::opensave::cfg::settings(Sorting2) == "increase"}	{
					if {[info exists _filelistdirmap]}	{set _filelistdirmap   [lsort -integer -index 3 $_filelistdirmap]}
					if {[info exists _filelistfilemap]}	{set _filelistfilemap  [lsort -integer -index 3 $_filelistfilemap]}
				}
				if {$::opensave::cfg::settings(Sorting2) == "decrease"}	{
					if {[info exists _filelistdirmap]}	{set _filelistdirmap   [lsort -integer -decreasing -index 3 $_filelistdirmap]}
					if {[info exists _filelistfilemap]}	{set _filelistfilemap  [lsort -integer -decreasing -index 3 $_filelistfilemap]}
				}
			}
			if {$::opensave::cfg::settings(Sorting1) == "owner"}	{
				$::opensave::OwnerColumn configure -background $::opensave::cfg::settings(SortedColumnBg)
				$::opensave::OwnerColumn configure -foreground $::opensave::cfg::settings(SortedColumnFg)
				if {$::opensave::cfg::settings(Sorting2) == "increase"}	{
					if {[info exists _filelistdirmap]}	{set _filelistdirmap   [lsort -dictionary -index 4 $_filelistdirmap]}
					if {[info exists _filelistfilemap]}	{set _filelistfilemap  [lsort -dictionary -index 4 $_filelistfilemap]}
				}
				if {$::opensave::cfg::settings(Sorting2) == "decrease"}	{
					if {[info exists _filelistdirmap]}	{set _filelistdirmap   [lsort -dictionary -decreasing -index 4 $_filelistdirmap]}
					if {[info exists _filelistfilemap]}	{set _filelistfilemap  [lsort -dictionary -decreasing -index 4 $_filelistfilemap]}
				}
			}

			::opensave::p.InsertCorrectIcon $::opensave::FileListColumn "___!UPDIR_ICON!___"
			$::opensave::FileListColumn insert end " .."
			if {[llength $_filelist] > 0}	{$::opensave::FileListColumn insert end "\n"}

			::opensave::p.InsertCorrectIcon $::opensave::SizeColumn "___!BLANK_DIR_ICON!___"
			$::opensave::SizeColumn insert end ""
			if {[llength $_filelist] > 0}	{$::opensave::SizeColumn insert end "\n"}

			::opensave::p.InsertCorrectIcon $::opensave::DateColumn "___!BLANK_DIR_ICON!___"
			$::opensave::DateColumn insert end ""
			if {[llength $_filelist] > 0}	{$::opensave::DateColumn insert end "\n"}

			::opensave::p.InsertCorrectIcon $::opensave::PermissionColumn "___!BLANK_DIR_ICON!___"
			$::opensave::PermissionColumn insert end ""
			if {[llength $_filelist] > 0}	{$::opensave::PermissionColumn insert end "\n"}

			::opensave::p.InsertCorrectIcon $::opensave::OwnerColumn "___!BLANK_DIR_ICON!___"
			$::opensave::OwnerColumn insert end ""
			if {[llength $_filelist] > 0}	{$::opensave::OwnerColumn insert end "\n"}

			set ::opensave::size_longest 0
			set ::opensave::owner_longest 0

			set _count 0
			if {[info exists _filelistdirmap]}	{
				foreach _fmap $_filelistdirmap {
					incr _count
					::opensave::p.InsertCorrectIcon $::opensave::FileListColumn [lindex $_fmap 0]
					$::opensave::FileListColumn insert end " [lindex $_fmap 0]"
					if {$_count < [llength $_filelist]}	{$::opensave::FileListColumn insert end "\n"}

					::opensave::p.InsertCorrectIcon $::opensave::SizeColumn "___!BLANK_DIR_ICON!___"
					set _size [::opensave::p.FormatUnits [lindex $_fmap 1]]
					$::opensave::SizeColumn insert end $_size
					if {$_count < [llength $_filelist]}	{$::opensave::SizeColumn insert end "\n"}
					set _size_length [string length $_size]
					if {$_size_length > $::opensave::size_longest} {set ::opensave::size_longest $_size_length}

					::opensave::p.InsertCorrectIcon $::opensave::DateColumn "___!BLANK_DIR_ICON!___"
					set _mtime [clock format [lindex $_fmap 2] -format "%Y-%m-%d  %H:%M:%S"]
					$::opensave::DateColumn insert end $_mtime
					if {$_count < [llength $_filelist]}	{$::opensave::DateColumn insert end "\n"}

					::opensave::p.InsertCorrectIcon $::opensave::PermissionColumn "___!BLANK_DIR_ICON!___"
					set _perms "[string range [lindex $_fmap 3] 3 end]   [::opensave::p.Deoctalize [lindex $_fmap 3]]"
					$::opensave::PermissionColumn insert end $_perms
					if {$_count < [llength $_filelist]}	{$::opensave::PermissionColumn insert end "\n"}

					::opensave::p.InsertCorrectIcon $::opensave::OwnerColumn "___!BLANK_DIR_ICON!___"
					set _owner "[lindex $_fmap 4]:[lindex $_fmap 5]"
					$::opensave::OwnerColumn insert end $_owner
					if {$_count < [llength $_filelist]}	{$::opensave::OwnerColumn insert end "\n"}
					set _owner_length [string length $_owner]
					if {$_owner_length > $::opensave::owner_longest} {set ::opensave::owner_longest $_owner_length}
				}
			}
			if {[info exists _filelistdirmap] && [info exists _filelistfilemap]}	{
				::opensave::p.InsertCorrectIcon $::opensave::FileListColumn "___!BLANK_FILE_ICON!___"
				$::opensave::FileListColumn insert end "----\n"
				::opensave::p.InsertCorrectIcon $::opensave::panedwindow.frame_2.size "___!BLANK_FILE_ICON!___"
				$::opensave::SizeColumn insert end "----\n"
				::opensave::p.InsertCorrectIcon $::opensave::panedwindow.frame_2.date "___!BLANK_FILE_ICON!___"
				$::opensave::DateColumn insert end "----\n"
				::opensave::p.InsertCorrectIcon $::opensave::panedwindow.frame_2.permission "___!BLANK_FILE_ICON!___"
				$::opensave::PermissionColumn insert end "----\n"
				::opensave::p.InsertCorrectIcon $::opensave::panedwindow.frame_2.owner "___!BLANK_FILE_ICON!___"
				$::opensave::OwnerColumn insert end "----\n"
			}

			if {[info exists _filelistfilemap]}	{
				foreach _fmap $_filelistfilemap {
					incr _count
					::opensave::p.InsertCorrectIcon $::opensave::FileListColumn [lindex $_fmap 0]
					$::opensave::FileListColumn insert end " [lindex $_fmap 0]"
					if {$_count < [llength $_filelist]}	{$::opensave::FileListColumn insert end "\n"}

					::opensave::p.InsertCorrectIcon $::opensave::panedwindow.frame_2.size "___!BLANK_FILE_ICON!___"
					set _size [::opensave::p.FormatUnits [lindex $_fmap 1]]
					$::opensave::panedwindow.frame_2.size insert end $_size
					if {$_count < [llength $_filelist]}	{$::opensave::panedwindow.frame_2.size insert end "\n"}
					set _size_length [string length $_size]
					if {$_size_length > $::opensave::size_longest} {set ::opensave::size_longest $_size_length}

					::opensave::p.InsertCorrectIcon $::opensave::panedwindow.frame_2.date "___!BLANK_FILE_ICON!___"
					set _mtime [clock format [lindex $_fmap 2] -format "%Y-%m-%d  %H:%M:%S"]
					$::opensave::panedwindow.frame_2.date insert end $_mtime
					if {$_count < [llength $_filelist]}	{$::opensave::panedwindow.frame_2.date insert end "\n"}

					::opensave::p.InsertCorrectIcon $::opensave::panedwindow.frame_2.permission "___!BLANK_FILE_ICON!___"
					set _perms "[string range [lindex $_fmap 3] 2 end]   [::opensave::p.Deoctalize [lindex $_fmap 3]]"
					$::opensave::panedwindow.frame_2.permission insert end $_perms
					if {$_count < [llength $_filelist]}	{$::opensave::panedwindow.frame_2.permission insert end "\n"}

					::opensave::p.InsertCorrectIcon $::opensave::panedwindow.frame_2.owner "___!BLANK_FILE_ICON!___"
					set _owner "[lindex $_fmap 4]:[lindex $_fmap 5]"
					$::opensave::panedwindow.frame_2.owner insert end $_owner
					if {$_count < [llength $_filelist]}	{$::opensave::panedwindow.frame_2.owner insert end "\n"}
					set _owner_length [string length $_owner]
					if {$_owner_length > $::opensave::owner_longest} {set ::opensave::owner_longest $_owner_length}
				}
			}
			$::opensave::SizeColumn configure -width $::opensave::size_longest
			$::opensave::OwnerColumn configure -width $::opensave::owner_longest
			p.LockAllColumns

			focus $::opensave::FileListColumn
			update idletasks
			event generate $::opensave::FileListColumn <Control-Home>
			::opensave::p.Update.Widgets.On.Any.Action

			set _insertLine 1
			set _insertCol 0
			set ::INSERTPOINT $_insertLine.$_insertCol
			$::opensave::FileListColumn mark set insert $::INSERTPOINT

			$::opensave::FileListColumn mark set selected "1.0 lineend"
			$::opensave::FileListColumn tag add "selected" 1.2 "1.0 lineend +1c"
			
			$::opensave::statusbar configure -text "$::opensave::FILECOUNT files, $::opensave::DIRCOUNT subdirs, $::opensave::ITEMSUM items, $::opensave::FILESIZESUM total."
		}
	}



	::opensave::p.FirstVars
	::opensave::p.config
	::opensave::p.MakeWidgets
	::opensave::p.RunFunction open
	
	vwait ::opensave::OUTPUT
	destroy $::opensave::w
	return $::opensave::OUTPUT
}
puts [::opensave::opensave2022 open]
exit

# HOW TO USE IT:
# source opensave.tcl
# run this command: ::opensave::opensave2022 open
# coming soon:
# ::opensave::opensave2022 opensingle
# ::opensave::opensave2022 openmulti
# ::opensave::opensave2022 save
