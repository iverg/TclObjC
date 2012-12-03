/*
Copyright (c) 2005-2012, Igor Viarheichyk
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met: 

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer. 
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution. 

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#include <stdio.h>
#include <tcl.h>
#import <objc/objc-runtime.h>
#import <Foundation/Foundation.h>

static IMP OriginalDealloc;
/* Mapping of Tcl method types to ObjectiveC type string */
struct {
	char *name, *type;
	int len;
} typeMapping[] = { {"(id)", "@", sizeof(id)},
		    {"(string)", "r*", sizeof(char*)},
		    {"(int)", "i", sizeof(int)},
		    {"(integer)", "i", sizeof(int)},
		    {"(BOOL)", "c", sizeof(char)},
		    {"(void)", "v", 0},
		    {"(NSRect)", @encode(NSRect), sizeof(NSRect)},
		    {"(CGRect)", @encode(NSRect), sizeof(NSRect)},
		    {"(NSPoint)", @encode(NSPoint), sizeof(NSPoint)},
		    {NULL, NULL, 0},
		  }; 

Tcl_Obj* ObjCommand(Tcl_Interp *interp, id objid, BOOL isClass);

/* Convert data from Objective C runtime type to Tcl type */
Tcl_Obj* ObjC2Tcl(Tcl_Interp *interp, const char *type,
		void *obj, const char ** outtype, void**outobj)
{
	Tcl_Obj	*result = NULL;
	int i;
	
	/* Ignore encoding modifier for now */
	switch(type[0]) {
		case 'r': case 'R': case 'o': case 'O': case 'n': case 'N':
		case 'V': type++;
	}

	switch(type[0]) {
		case _C_CLASS:
			result = ObjCommand(interp, *(id*)obj, YES);
			if (outobj) *outobj = obj + sizeof(id);
			break;

		case _C_ID:
			result = ObjCommand(interp, *(id*)obj, NO);
			if (outobj) *outobj = obj + sizeof(id);
			break;

		case _C_SEL:
		case _C_CHARPTR:
			result = Tcl_NewStringObj(*(char **)obj, 
					strlen(*(char **)obj));
			if (outobj) *outobj = obj + sizeof(char*);
			break;
		case _C_SHT:
		case _C_USHT:
			result = Tcl_NewIntObj(*(short*)obj);
			if (outobj) *outobj = obj + sizeof(short);
			break;

		case _C_INT:
		case _C_UINT:
			result = Tcl_NewIntObj(*(int*)obj);
			if (outobj) *outobj = obj + sizeof(int);
			break;

		case _C_ULNG:
		case _C_LNG:
			result = Tcl_NewLongObj(*(long*)obj);
			if (outobj) *outobj = obj + sizeof(long);
			break;

		case _C_ULNG_LNG:
		case _C_LNG_LNG:
			result = Tcl_NewWideIntObj(*(long long*)obj);
			if (outobj) *outobj = obj + sizeof(long);
			break;

		case _C_DBL:
			result =  Tcl_NewDoubleObj(*(double*)obj);
			if (outobj) *outobj = obj + sizeof(double);
			break;
		
		case _C_FLT:
			result = Tcl_NewDoubleObj(*(float*)obj);
			if (outobj) *outobj = obj + sizeof(float);
			break;

		case _C_CHR:
			result = Tcl_NewIntObj(*(char*)obj);
			if (outobj) *outobj = obj + sizeof(char);
			break;

		case _C_VOID:
			result = Tcl_NewStringObj("", 0);
			if (outobj) *outobj = obj;
			break;

		case _C_STRUCT_B:
			/* Skip structure name */
			for(;*type && *type != '=';type++);
			result = Tcl_NewListObj(0, NULL);
			for(type++, i = 0; 
			    *type && *type != _C_STRUCT_E; 
			    type++, i++) {
				Tcl_ListObjAppendElement(interp, result,
				   ObjC2Tcl(interp, type, obj, &type, &obj));
			}
			if (outtype) *outtype = type++;
			break;
		default:
			printf("Can not convert %s to Tcl object\n", type);
			result = Tcl_NewStringObj("", 0);
	}
	return result;
}

/* Convert Tcl object to Objective C runtime type and store it in
   specified location. Returns size of converted argument in bytes, 
   or zero if conversion failed.
*/
int Tcl2ObjC(Tcl_Interp *interp, const char *type, Tcl_Obj *obj, 
		void *arg, const char **outtype)
{
	int		i, cnt, size;
	Tcl_CmdInfo	info;
	double		tmp2;
	//NSSwappedFloat	f;

	/* Ignore encoding modifier for now */
	switch(type[0]) {
		case 'r': case 'R': case 'o': case 'O': case 'n': case 'N':
		case 'V': type++;
	}

	switch(type[0]) {
		case _C_ID:
			if (Tcl_GetCommandInfo(interp, 
				Tcl_GetStringFromObj(obj, NULL), &info)) {
				size = sizeof(id);
				*((id*)arg) = (id)info.objClientData;
			} else {
				size = -1;
				printf("Invalid object\n");
			}
			break;

		case _C_CHARPTR:
			*(char**)arg = Tcl_GetStringFromObj(obj, NULL);
			size = sizeof(char*);
			break;

		case _C_UCHR:
		case _C_CHR:
			if(Tcl_GetIntFromObj(interp, obj, &i) == TCL_OK) {
				*(char*)arg = (char)i;
				size = sizeof(char);	
			} else 	size = -1;
			break;

		case _C_USHT:
		case _C_SHT:
			if(Tcl_GetIntFromObj(interp, obj, &i) == TCL_OK) {
				*(short*)arg = (short)i;
				size = sizeof(short);	
			} else 	size = -1;
			break;

		case _C_UINT:
		case _C_INT:
			if (Tcl_GetIntFromObj(interp, obj, (int*)arg)==TCL_OK)
				size = sizeof(int);
			else	size = -1;
			break;

		case _C_ULNG:
		case _C_LNG:
			if (Tcl_GetLongFromObj(interp, obj, 
				(long*)arg)==TCL_OK)
				size = sizeof(long);
			else	size = -1;
			break;

		case _C_LNG_LNG:
		case _C_ULNG_LNG:
			if (Tcl_GetWideIntFromObj(interp, obj, 
				(Tcl_WideInt*)arg) == TCL_OK)
			     size = sizeof(long long);
			else size = -1;	
			break;

		case _C_DBL:
			size = sizeof(double);
			Tcl_GetDoubleFromObj(interp, obj, (double*)arg);
			//printf("Sizeof double is %d, value is %0.16g\n", 
			//	size, *(double*)arg);
			break;
		
		case _C_FLT:
			size = sizeof(float);
			Tcl_GetDoubleFromObj(interp, obj, &tmp2);
			*(float*)arg = (float)tmp2;
			//printf("Sizeof float is %d, value is %0.7g / %08x\n", 
			//	size, *(float*)arg, *(unsigned*)arg);
			break;

		case _C_CLASS:
			*(Class*)arg = objc_getClass(
				Tcl_GetStringFromObj(obj, NULL));
			size = sizeof(Class);
			break;

		case _C_SEL:
			*(SEL*)arg = sel_getUid(
				Tcl_GetStringFromObj(obj, NULL));

			size = sizeof(SEL);
			break;
		case _C_UNION_B:
			printf("No union support yet: %s", type);
			size = 0;
			break;

		case _C_STRUCT_B:
			/* Skip structure name */
			for(;*type && *type != '=';type++);
			for(type++, i = 0, size = 0; 
			    *type && *type != _C_STRUCT_E; 
			    type++, i++) {
				Tcl_Obj	*item;
				if (Tcl_ListObjIndex(interp, obj, i, &item)
					== TCL_OK) size += Tcl2ObjC(interp,
						 type, item, arg+size, &type);
				else {
					size = -1;
					break;
				}
			}
			if (outtype) *outtype = type++;
			break;
		case _C_ARY_B:
			/* Get array length */ 
			for(cnt = 0, type++; *type>='0' && *type<='9';
				type++, cnt = cnt*10+(*type-'0'));
			/* Check if length matches */
			if (Tcl_ListObjLength(interp, obj, &i) != TCL_OK ||
			    i != cnt ) {
				size = -1;
				//TODO: verbose error reporting here
				break;
			}
			/* Iterate through Tcl list to fill array items */
			for(i=0;i<cnt;i++) {
				Tcl_Obj *item;
				if(Tcl_ListObjIndex(interp, obj, i, &item) == 
					TCL_OK) size += Tcl2ObjC(interp, 
						type, item, arg+size, NULL);
				else {
					size = -1;
					break;
				}
			}
			break;

		case _C_VOID:
			size = 0;
			break;

		case _C_UNDEF:
		default:
			printf("Unsupported type %s\n", type);
			size = -1;
	}

	return size;
}

int isType(const char* str)
{
	int	idx;

	/* Check type declaration syntax */
	if(!str || str[0]!='(' || str[strlen(str)-1]!=')')
		return -1;

	/* Try to find mapping */
	for(idx=0;typeMapping[idx].name && 
                  strcmp(str, typeMapping[idx].name); idx++);
	if (!typeMapping[idx].name) {
		return -2;
	} else return idx;
}

int ObjMethod(ClientData clientData, Tcl_Interp *interp, 
		int objc, Tcl_Obj *CONST objv[])
{
	int 		i, cnt;
	id		target, res;
	SEL		selector;
	Tcl_Obj		*selectorName;
	Tcl_Obj		*result;
	void		*ptr;

	const char	*ret_type;

	NSInvocation		*invocation;
	NSMethodSignature	*signature;
	NSAutoreleasePool	*pool;

	/* Check if selector is provided as arguiments. Otherwise return
	   Tcl representation according to class */
	if (objc < 2) {
		Tcl_SetObjResult(interp, objv[0]);
		return TCL_OK;
	}

	target = (id)clientData;
	
	selectorName = Tcl_NewStringObj(NULL, 0);
	
	/* Construct method selector */
	for (i=1,cnt=0;i<objc;i+=2) {
		Tcl_AppendObjToObj(selectorName, objv[i]);
	}
	
	selector = sel_getUid(Tcl_GetStringFromObj(selectorName, NULL));

	if(!strcmp(Tcl_GetStringFromObj(objv[0], NULL), "super")) {
		Tcl_SetStringObj(Tcl_GetObjResult(interp), 
			"Calls to super are not currently suppoeted", 43);
		return TCL_ERROR;
	}

	signature = [target methodSignatureForSelector: selector];
	if (signature == nil) {
		Tcl_SetStringObj(Tcl_GetObjResult(interp), 
			"Signature for selector not found.", 33);
		return TCL_ERROR;
	}
	
	pool = [NSAutoreleasePool new];
	invocation = [[NSInvocation invocationWithMethodSignature: signature] retain];
	[pool release];
	[invocation setSelector: selector];
	[invocation setTarget: target];
	cnt = [signature numberOfArguments];

	if (cnt > 2) {
		/* Allocate memory block enough to keep any of parameter */
		ptr = malloc([signature frameLength]);
		if (!ptr) {
			[invocation release];
			return TCL_ERROR;
		}

		for(i=2;i<cnt;i++) {
			Tcl2ObjC(interp, [signature getArgumentTypeAtIndex: i], 
				objv[(i-1)*2], ptr, NULL);
			[invocation setArgument: ptr atIndex: i];
		}
		free(ptr);
	}

	[invocation invoke];

	ret_type = [signature methodReturnType];
	/* If method does returns void, do not bother with
	   return value handling, just return empty string.
	*/
	if (ret_type[0]==_C_VOID) {
		[invocation release];
		Tcl_SetObjResult(interp, Tcl_NewStringObj( NULL, 0));
		return TCL_OK;
	}

	/* Check if additional memory should be allocated to store result.
	   This is only needed it result size is greater that sizeof(id)
	*/
	i = [signature methodReturnLength];
	if (i>sizeof(res)) {
		ptr = malloc(i);
		if (!ptr) return TCL_ERROR;
	} else ptr = &res;

	[invocation getReturnValue: &res];
	
	result = ObjC2Tcl(interp, ret_type , ptr, NULL,NULL);
	
	if (i>sizeof(res)) free(ptr);

	[invocation release];

	if ( NULL == result ) {	
		Tcl_SetStringObj(Tcl_GetObjResult(interp), 
			"Return value coersion error.", 25);
		return TCL_ERROR;
	} else Tcl_SetObjResult(interp, result);
	return TCL_OK;
}

/* Object or class deletion handler - invoke release method */
void ObjDelete(ClientData clientData)
{
	id target = (id)clientData;
	[target release];
}

/* Check if object commands exists, and create new command otherwise.
   Return command as result */
Tcl_Obj* ObjCommand(Tcl_Interp *interp, id objid, BOOL isClass)
{
	char		buffer[32] = "nil";
	const char	*ptr = buffer;
	Tcl_CmdInfo	info;

	if (objid != nil) {
		if (isClass) 
			ptr = class_getName((Class)objid);
		else {
			sprintf(buffer, "::ObjC::obj%x", (unsigned)objid);
		}

		if (!Tcl_GetCommandInfo(interp, ptr, &info)) {
			Tcl_CreateObjCommand(interp, ptr, ObjMethod, 
				(ClientData)objid, ObjDelete);
		}
	}
	return Tcl_NewStringObj(ptr, strlen(ptr));
}


void InitClasses(Tcl_Interp *interp)
{
	int i;
	id obj;
	int numClasses = objc_getClassList(NULL, 0);
	Class *buf;
	buf = (Class*)malloc(sizeof(Class)*numClasses);
	objc_getClassList(buf, numClasses);
	for(i=0;i<numClasses;i++) {
		const char *name = class_getName(buf[i]);
		obj = (id)objc_lookUpClass(name);
		Tcl_CreateObjCommand(interp, name, ObjMethod,
			(ClientData)obj, ObjDelete);
	}
}

/* This procedure is used to get pointer to existsing class or create new one
   if it is not exists yet
*/
Class ImplementClass (Tcl_Interp *interp, char *name, char *superClassName)
{
	Class myClass, superClass = nil;
	
	/* Check if class name is valid */
	if (!name) {
		Tcl_SetStringObj(Tcl_GetObjResult(interp), 
			"Class name is not valid", 22);
		return nil;
	}

	/* If superclass name is provided, check if it exists*/
	if (superClassName) {
		superClass = objc_lookUpClass(superClassName);
		if (nil == superClass) {
			Tcl_SetStringObj(Tcl_GetObjResult(interp), 
				"Superclass does not exists", 27);
			return nil;
		}
	}

	/* Check if class with same name already exists */
	myClass = objc_lookUpClass(name);
	
	/* If class already defined, check for superclass match*/
	if (nil != myClass) {
		if (superClass && class_getSuperclass(myClass) != superClass) {
			Tcl_SetStringObj(Tcl_GetObjResult(interp), 
				"Superclass name conflicts with existing implementation", 54);
			return nil;
		}
		return myClass;
	}

	/* If superclass is not provided, consider it NSObject */
	if (!superClass) superClass = objc_lookUpClass("NSObject");
	
	if (nil == superClass) {
		printf("This should not happen! What happened to NSObject?\n");
		return nil;
	}

	myClass = objc_allocateClassPair(superClass, name, 0);

	objc_setAssociatedObject(myClass, "interp", [NSValue valueWithPointer: interp], OBJC_ASSOCIATION_ASSIGN);
	return myClass;
}

Tcl_Obj* getProcNameForClass(Class c, Tcl_Obj *selector) 
{
	char buffer[64];
	Tcl_Obj *res;
	int len;

	len = snprintf(buffer, sizeof(buffer), "::ObjC::%p_", c);
	res = Tcl_NewStringObj(buffer, len);
	Tcl_AppendObjToObj(res, selector);

	return res;	
}

/* Tcl script method Implementation handler */
id TclMethodIMP (id target, SEL selector, ...)
{
	int		i, cnt;
	id		res = nil;
	char 		typedata[128];
	char		*type;
	const char	*selName;
	Method		method;
	Tcl_Obj		*params = Tcl_NewListObj(0, NULL);
	Tcl_Interp	*interp = [objc_getAssociatedObject(object_getClass(target), "interp") pointerValue];
	va_list		arg;
	Class		c;


	selName = sel_getName(selector);

	c = object_getClass(target);
	Tcl_ListObjAppendElement(interp, params, 
		getProcNameForClass(c, Tcl_NewStringObj(selName, strlen(selName))));

	method = class_getInstanceMethod(c, selector);
	cnt = method_getNumberOfArguments(method);
	
	va_start(arg, selector);
	for (i=2; i < cnt; i++)
	 {
		method_getArgumentType(method, i, typedata, sizeof(typedata));
		type = typedata;
		{
			Tcl_Obj	*result = NULL;

			/* Ignore encoding modifier for now */
			switch(type[0]) {
				case 'r': case 'R': case 'o': case 'O': case 'n': case 'N':
				case 'V': type++;
			}

			switch(type[0]) {
				case _C_CLASS:
					result = ObjCommand(interp, va_arg(arg, id), YES);
					break;

				case _C_ID:
					result = ObjCommand(interp, va_arg(arg, id), NO);
					break;

				case _C_SEL:
				case _C_CHARPTR:
					{
						char *str = va_arg(arg, char*);
						result = Tcl_NewStringObj(str, strlen(str)); 
					}
					break;
				case _C_SHT:
				case _C_USHT:
				case _C_CHR:
				case _C_INT:
				case _C_UINT:
					result = Tcl_NewIntObj(va_arg(arg, int));
					break;

				case _C_ULNG:
				case _C_LNG:
					result = Tcl_NewLongObj(va_arg(arg, long));
					break;

				case _C_DBL:
				case _C_FLT:
					result = Tcl_NewDoubleObj(va_arg(arg, double));
					break;

				case _C_VOID:
					result = Tcl_NewStringObj("", 0);
					break;

				case _C_STRUCT_B:
					/* For now only limited set of known structures is supported
					   to allow Tcl callbacks. Extend global typeMapping to add more
					   sctructures. */

					/* Determine structure name from the encoded type */
					{	int idx;
						union {
							NSRect r;
							NSPoint p;
						} u;

						for(idx=1;typedata[idx] && typedata[idx] != '='; idx++);
						typedata[0] = '(';
						if (typedata[idx])
							typedata[idx++]=')';
						if (typedata[idx])
							typedata[idx]='\0';

						/* Lookup in typeMapping */
						idx = isType(typedata);
						switch (idx) {
							case 6:
							case 7: 
								u.r = va_arg(arg, NSRect);
								break;
							case 8:
								u.p = va_arg(arg, NSPoint);
								break;
							default:
								printf("Structure %s is not supported\n", typedata);
								result = Tcl_NewStringObj("", 0);
								continue;
						}
					
						method_getArgumentType(method, i, typedata, sizeof(typedata));
						result = ObjC2Tcl(interp, typedata, &u, NULL, NULL);
					}
					break;
				default:
					printf("Can not convert %s to Tcl object\n", type);
					result = Tcl_NewStringObj("", 0);
			}
			if (result) {
				Tcl_ListObjAppendElement(interp, params, result);
			}
		}
	}
	va_end(arg);

	/* Create aliases for self and super */
	Tcl_CreateObjCommand(interp, "self", ObjMethod, 
		(ClientData)target, NULL);

	/* Create aliases for self and super */
	Tcl_CreateObjCommand(interp, "super", ObjMethod, 
		(ClientData)target, NULL);

	if (Tcl_EvalObjEx(interp, params, 0) == TCL_OK) {
		method_getReturnType(method, typedata, sizeof(typedata));
		Tcl2ObjC(interp, typedata, 
			Tcl_GetObjResult(interp), &res, NULL);
	} else {
		/*TODO: add error reporting here */
	}
	Tcl_DeleteCommand(interp, "super");
	Tcl_DeleteCommand(interp, "self");
	
	return res;
}

int AddMethodCommand(ClientData clientData, Tcl_Interp *interp, 
		int objc, Tcl_Obj *CONST objv[])
{
	Class	 c = (Class)clientData;
	Tcl_Obj	 *selectorName = Tcl_NewStringObj(NULL, 0);
	Tcl_Obj	 *tmp;
	Tcl_Obj	 *script[4];
	Tcl_Obj	 *arglist = Tcl_NewListObj(0, NULL);
	Tcl_Obj  *types = Tcl_NewStringObj("@0:4", 4);

	char	*str, *retType;
	int	i, idx, frame = sizeof(id) + sizeof(SEL);
	char	buffer[128];
	int	result;
	enum	{ selector, typearg, arg } waitfor;

	
	if (objc < 3) {
		Tcl_WrongNumArgs(interp, 1, objv, "selector body");
		return TCL_ERROR;
	}

	// First check if return value type is specified
	i = 1;
	idx = isType(Tcl_GetStringFromObj(objv[i], NULL));
	if (idx >= 0) {
		retType = typeMapping[idx].type;
		i++;
	} else if (idx == -2) {
		Tcl_WrongNumArgs(interp, 1, objv, "selector body");
		return TCL_ERROR;
	} else retType = "v";
	
	for(waitfor=selector;i<objc-1;i++) {
		str = Tcl_GetStringFromObj(objv[i], NULL);
		switch(waitfor) {
			case selector:
				if (str[strlen(str)-1]!=':' && objc > 4) {
					Tcl_SetStringObj(
						Tcl_GetObjResult(interp), 
						"Selector part should end with colon", 35);
					return TCL_ERROR;
				}

				Tcl_AppendObjToObj(selectorName, objv[i]);
				waitfor = typearg;
				break;
			case typearg:
				idx = isType(str);
				if (idx >= 0) {
					waitfor = arg;
					break;
				} else if(idx==-2) {
					Tcl_WrongNumArgs(interp, 1, objv,
						"selector body");
					return TCL_ERROR;
				} else idx = 0;
			case arg:
				Tcl_ListObjAppendElement(interp, 
					arglist, objv[i]);
				sprintf(buffer, "%s%d", typeMapping[idx].type,
                     			frame);
				Tcl_AppendStringsToObj(types, buffer, NULL);
				frame += typeMapping[idx].len;
				waitfor = selector;
				break;	
		}
	}

	sprintf(buffer, "%s%d", retType, frame);
	tmp = Tcl_NewStringObj(buffer, strlen(buffer));
	Tcl_AppendObjToObj(tmp, types);

	/* Create Tcl procedure for selector */
	script[0] = Tcl_NewStringObj("proc", 4);
	script[1] = getProcNameForClass(c, selectorName);
	script[2] = arglist;
	script[3] = objv[objc-1];
	result = Tcl_EvalObjv(interp, 4, script, TCL_EVAL_DIRECT);
	if (result != TCL_OK) { 
		return result;
	}

	if (class_addMethod(c, sel_registerName(Tcl_GetStringFromObj(selectorName, NULL)),
			    TclMethodIMP, Tcl_GetStringFromObj(tmp, NULL))) {
		return TCL_OK;
	} else {
		return TCL_ERROR;
	}
}

int ImplementationCommand(ClientData clientData, Tcl_Interp *interp, 
		int objc, Tcl_Obj *CONST objv[])
{
	char	*className = nil, *superClassName = NULL, *check;
	int	len;
	Class 	c;
	int	result;

	switch(objc) {
		case 5:
			check = Tcl_GetStringFromObj(objv[2], &len);
			if (len!=1 || check[0]!=':') break;
		case 4:
			superClassName = Tcl_GetStringFromObj(
				objv[objc-2], NULL);
		case 3:
			className = Tcl_GetStringFromObj(objv[1], NULL);
	}

	if (!className) {
		Tcl_WrongNumArgs(interp, 1, objv, 
			"className ?: superClass? body");
		return TCL_ERROR;
	}

	c = ImplementClass(interp, className, superClassName);
	if (!c) {
		return TCL_ERROR;
	}
	objc_registerClassPair(c);
	
	/* Create commands for adding methods */
	Tcl_CreateObjCommand(interp, "-", AddMethodCommand, 
		(ClientData)c, NULL);
	Tcl_CreateObjCommand(interp, "+", AddMethodCommand, 
		(ClientData)c->isa, NULL);

	result = Tcl_EvalObjEx(interp, objv[objc-1], TCL_EVAL_DIRECT);

	/* After leaving implementation scope delete method creation command */
	Tcl_DeleteCommand(interp, "-");
	Tcl_DeleteCommand(interp, "+");

	if (result != TCL_OK) { 
		return result;
	}
	/* Create class command and return its name as a result */
	Tcl_SetObjResult(interp, ObjCommand(interp, c, YES));

	return TCL_OK;
}


void MyDealloc(id target, SEL selector, ...)
{
	printf("Deallocating memory for %x\n", (int)target);
	OriginalDealloc(target, selector);
}

int FastNSString(ClientData clientData, Tcl_Interp *interp, 
		int objc, Tcl_Obj *CONST objv[])
{
	char *str;

	if (objc != 2) {
		Tcl_WrongNumArgs(interp, 1, objv, "string");
		return TCL_ERROR;
	}
	
	//str = Tcl_GetStringFromObj(objv[1], &len);
	str = Tcl_GetString(objv[1]);
	Tcl_SetObjResult(interp, ObjCommand(interp, 
		[NSString stringWithUTF8String:str], NO));
	return TCL_OK;
}

int Cocoa_Init(Tcl_Interp *interp)
{
	// TODO: Add pool release
	//[[NSAutoreleasePool alloc] init];
	Method method;

	if (Tcl_InitStubs(interp, "8.1", 0) == NULL) 
		return TCL_ERROR;

	InitClasses(interp);

	/* Syntactic sugar: @ command for NSString fast creation*/
	Tcl_CreateObjCommand(interp, "@", FastNSString, NULL, NULL);
	
	/* Create nil command to represent object with nil id*/
	Tcl_CreateObjCommand(interp, "nil", ObjMethod, (ClientData)nil,
		ObjDelete);
	
	/* Create command for class implementation */
	Tcl_CreateObjCommand(interp, "implementation", 
		ImplementationCommand, NULL, NULL);
	
	/* Replace NSObject dealloc implemnetation with own one
	   to delete assitiated Tcl object
	*/
	method = class_getInstanceMethod(objc_getClass("NSObject"), 
		sel_getUid("dealloc"));
	if (method) {
		OriginalDealloc = method_getImplementation(method);
		//method->method_imp = MyDealloc;
	}

	Tcl_PkgProvide(interp, "Cocoa", "1.0");

	return TCL_OK;
}

int Cocoa_SafeInit(Tcl_Interp *interp) { return TCL_ERROR; }

