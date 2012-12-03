lappend auto_path . ..
package require Cocoa

[NSAutoreleasePool alloc] init

rename [NSFontManager sharedFontManager] FontManager

set fonts [FontManager availableFonts]

# Dump fonts as a single plist
puts [[$fonts description] UTF8String]

# Enumerate and display each font
set enumerator [$fonts objectEnumerator]
while { [set font [$enumerator nextObject]] != "nil"} {
	puts [$font UTF8String]
}


