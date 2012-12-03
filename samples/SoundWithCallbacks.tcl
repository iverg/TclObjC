lappend auto_path . ..

package require Cocoa

[NSAutoreleasePool alloc] init

implementation MyApp : NSObject {
	- run {
		global files
		if {![llength $files]} { 
			puts "All files were played"
			exit
		}
		set file [lindex $files 0]
		rename [[NSSound alloc] initWithContentsOfFile: [@ $file]\
			byReference: 1] player
		puts "Playing $file"
		set files [lrange $files 1 end]
		player setDelegate: self
		player play
	}

	- (void) sound: snd didFinishPlaying: (int) flag {
		puts "Done"
		rename player {}
		[self run]
	}
}

set files [glob /System/Library/Sounds/*.aiff]
[[MyApp alloc] init] run

# Need event loop to make callbacks work
[NSApplication sharedApplication] run

