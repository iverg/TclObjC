lappend auto_path . ..
package require Cocoa

proc objectForKey {dict key} {
	if {$dict == "nil" || ![$dict isKindOfClass: NSDictionary]} {
		return -code error "Can not access key $key of $dict"
	}
	set obj [$dict objectForKey: [@ [lindex $key 0]]]
	set key [lrange $key 1 end]
	if {[llength $key]} { 
		set obj [objectForKey $obj $key] 
	} else {
		set obj [[$obj description] UTF8String] 
	}
}

NSAutoreleasePool new
rename [NSDictionary dictionaryWithContentsOfFile: [@ /Library/Preferences/SystemConfiguration/preferences.plist]] preferences

puts "Computer name is [objectForKey preferences {System System ComputerName}]"
if {[catch {
	set proxy [objectForKey preferences {NetworkServices 0 Proxies HTTPProxy}]
	set port [objectForKey preferences {NetworkServices 0 Proxies HTTPPort}]
	puts "Proxy is $proxy:$port"
} r]} {
	puts "HTTP proxy is not set"
}
