OBJ = cocoa.o
NAME = Cocoa.dylib
CFLAGS += -I/Library/Frameworks/Tcl.framework/headers -Wall

.PHONY: clean

$(NAME): $(OBJ)
	$(CC) -dynamiclib -g -o $(NAME) -framework Tcl -framework Cocoa $(OBJ)
clean: 
	rm $(OBJ)
	rm $(NAME)

