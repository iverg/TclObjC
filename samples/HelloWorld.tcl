lappend auto_path . ..
package require Cocoa

implementation AppDelegate : NSObject {
	- applicationDidFinishLaunching: notification {
		puts "Hello world"
	}

	- (void) sayHello: sender {
		speak "Hello $::env(USER)"
	}

	proc speak {str} {
		[[NSAppleScript alloc] initWithSource: [@ "say \"$str\""]]\
			executeAndReturnError: nil
		puts $str
	}
}

rename [NSAutoreleasePool new] pool
rename [NSApplication sharedApplication] app
app setDelegate: [[AppDelegate alloc] init]
set frame {{200.0 300.0} {250 100}}
set win [[NSWindow alloc] initWithContentRect: $frame styleMask: 15\
		 backing: 2 defer: 0]
$win setTitle: [@ "Hello World"]
$win setLevel: 3

set hel [[NSButton alloc] initWithFrame: {{10 10} {80 80}}]
[$win contentView] addSubview: $hel
$hel setBezelStyle: 4
$hel setTitle: [@ Hello]
$hel setTarget: [app delegate]
$hel setAction: sayHello:

set bye [[NSButton alloc] initWithFrame: {{100 10} {80 80}}]
[$win contentView] addSubview: $bye
$bye setBezelStyle: 4
$bye setTitle: [@ "Goodbye!"]
$bye setTarget: app
$bye setAction: stop:

$bye setSound: [[NSSound alloc]\
	initWithContentsOfFile: [@ /System/Library/Sounds/Basso.aiff]\
	byReference: 1]

$win display
$win orderFrontRegardless
pool release
app run
