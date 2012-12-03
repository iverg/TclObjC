lappend auto_path .
package require Cocoa

implementation HelloView : NSView {
	#- (void) gredrawRect: rect { puts "Hello" }
	puts Done
}

NSAutoreleasePool new
rename [NSApplication sharedApplication] app
rename [[NSWindow alloc] initWithContentRect: {{0 0} {450 200}} styleMask: 15 backing: 2 defer: 0] win
[HelloView alloc] initWithFrame: {{0 0} {450 200}}

win setOpaque: 0
#app run
