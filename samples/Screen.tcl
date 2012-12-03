
lappend auto_path . ..
package require Cocoa
rename [NSAutoreleasePool new] pool

set screen [NSScreen mainScreen]
if {$screen == "nil"} {
	puts "Can not get main screen"
} else {
	puts "Screen is [[screen deviceDescription] UTF8String]"
	puts "Frame: [$screen visibleFrame]"
}
