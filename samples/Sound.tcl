lappend auto_path .

package require Cocoa

[NSAutoreleasePool alloc] init

foreach file [glob  /System/Library/Sounds/*.aiff] {
	set snd [[[NSSound alloc]\
		initWithContentsOfFile: [@ $file]\
		byReference: 1] autorelease]
	$snd play
	after 500
}

