lappend auto_path .
package require Cocoa

NSAutoreleasePool new
proc speak {str} {
	[[NSAppleScript alloc] initWithSource: [@ "say \"$str\""]]\
		executeAndReturnError: nil
	puts $str
}

speak "Hello $env(USER)"

