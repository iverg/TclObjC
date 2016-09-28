# TclObjC

Tcl bindings to Objective C and Cocoa.

This small Tcl library provides integration of Tcl with Cocoa framework.

It allows create instance of any Cocoa class and invoke their methods from
Tcl scripts, create pure-Tcl class implementations and use them as delegates
in Cocoa API with a syntax resembling native Objective C.

Once Cocoa package is loaded, all Objective C classes are exported as Tcl
commands into global namespace.


## Commands

-   **implementation** *ClassName* [: *BaseClass*] *body*

    Defines new or extends existing Objective C class ClassName, derived from BaseClass.
    If BaseClass omitted, NSObject is assumed. Body is a Tcl block which is
    evaluated in the context of the class and can contain "-" and "+"
    commands to define instance and class methods.

-   \- *name* *body*
-   \- [*type*] *name* *body*
-   \- [*type>*] *part_of_name*: [*argument_type*] *parameter* *part_of_name*: *type* *parameter* ...? *body*

    Define instance method of a class. Type defines mapping to one of
    Objective-C types (see TYPES below). Type can be omitted, assuming (void)
    for return type and (id) for argument type. This command is only defined
    within implementation block. 
  
    Examples:
    *   `- init {}`  - method with no parameters and no return value
    *   `- (id) getValue {}` - method with no parameters returning id
    *   `- (void) sound: snd didFinishPlaying: (int) flag {}` - method with
     sound:didFinishPlaying: selector, having two parameters: id and int.

-   **\+** *name* *body*
-   **\+** [*type*] *name* *body*
-   **\+** [*type*] *part_of_name*: [*argument_type*] *parameter* *part_of_name*: *type* *parameter* ...? *body*
     Define class method. See description of "-" command for details.

-   **\@** *string*
    Syntactic sugar for [NSString createWithUTF8String: <string>], resembles
    `@"string"` syntax of Objective C.

-   **self**
    This command is only defined within instance or class method body and
    used to invoke another method of same object.
    Example:
	  *   `[self setValue: 10]`

-   **super**
    This command is only defined within instance or class method body and
    used to invoke super method of same object. NOT IMPLENTED YET.
    Example:
	  *   `[super setValue: 10]`

## Types
Currently following types are supported in method definitions:
*(id)*, *(string)*, *(integer)*, *(BOOL)*, *(void)*, *(NSRect)*, *(NSPoint)*


## Examples

1.  Get list of all Foundation classes
		```tcl
    info commands NS*
		```

2.  Calling methods
		```tcl
   	set className [NSObject class]
   	set dateString [[NSCalendarDate calendarDate] description]
   	set dict [NSDisctionary dictionaryWithContentsOfFile: [@ dict.plist]]
		```

3.  Defining own class
	  ```tcl
    implementation MyClass {
      - (id) init {
		    puts "Initialized"
		    self
      }
      
      - run {
	      puts "Do something"
      }
   }
   set obj [[MyClass alloc] init]
   $obj run
   ```

4.  Using Tcl callbacks
		```tcl
    implementation MyDelegate : NSObject {
	     (void) sound: snd didFinishPlaying: (inf) flag {
		      puts "Done"
 	     }
    }
    set snd [[NSSound alloc] initWithContentsOfFile: [@ filename.aiff] byReference: 1
    $snd setDelegate [[MyDelegate alloc] init]
		```

See samples directory for more examples.
