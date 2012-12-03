lappend auto_path .. .
package require Cocoa

NSAutoreleasePool new

puts "NSString:"
set str1 [@ Hello]
set str2 [@ world]
puts "Str1 object is $str1 ([$str1 UTF8String]), Str2 object is $str2 ([$str2 UTF8String])"

puts "Unsigned number:"
set obj [NSNumber numberWithUnsignedChar: 235]
puts "Number description [[$obj description] UTF8String]"
puts "ObjC type info: [$obj objCType]"

puts "Double:"
set obj [NSNumber numberWithDouble: 40000.00]
puts "Description: [[$obj stringValue] UTF8String]"
puts "ObjC type info: [$obj objCType]"

puts "Class versions"
NSObject setVersion: 2
puts "Now NSobject version is [NSObject version]"
puts Calendar

set datestr [[NSCalendarDate calendarDate] description]
puts "Now [$datestr UTF8String] of length [$datestr length]"

implementation TestClass : NSObject {
	- (string) test {
		return "[self] Test invoked"
	}
	
	- test2: (NSRect) rect {
		puts "Rect $rect"
	}
}

set test [[TestClass alloc] init]
puts "Object $test of class [$test class], superclass [$test superclass]"
puts [$test test]
$test test2: {{0 0} {100 200}}

puts "Number of Cocoa classes: [llength [info commands NS*]]"
