  --lua.h lauxlib.h lualib.h from Lua 5.4.4 (defines made enums, macros removed)
local ffi = require'ffi'
ffi.cdef[[

enum {
/* option for multiple returns in `lua_pcall' and `lua_call' */
	LUA_MULTRET = (-1),
/* pseudo-indices */
	LUA_REGISTRYINDEX = (-1001000),
  LUA_OK = 0,
	LUA_YIELD = 1,
	LUA_ERRRUN = 2,
	LUA_ERRSYNTAX = 3,
	LUA_ERRMEM = 4,
	LUA_ERRERR = 5,
/* basic types */
	LUA_TNONE = (-1),
	LUA_TNIL = 0,
	LUA_TBOOLEAN = 1,
	LUA_TLIGHTUSERDATA = 2,
	LUA_TNUMBER = 3,
	LUA_TSTRING = 4,
	LUA_TTABLE = 5,
	LUA_TFUNCTION = 6,
	LUA_TUSERDATA = 7,
	LUA_TTHREAD = 8,
  LUA_NUMTYPES = 9
};

typedef struct lua_State lua_State;
typedef int64_t (*lua_CFunction) (lua_State *L);

/* functions that read/write blocks when loading/dumping Lua chunks */
typedef const char * (*lua_Reader) (lua_State *L, void *ud, size_t *sz);
typedef int64_t (*lua_Writer) (lua_State *L, const void* p, size_t sz, void* ud);

/* type of numbers in Lua */
typedef long double lua_Number;

/* type for integer functions */
typedef long long lua_Integer;

/* state manipulation */

void       (lua_close) (lua_State *L);
lua_State *(lua_newthread) (lua_State *L);
lua_CFunction (lua_atpanic) (lua_State *L, lua_CFunction panicf);

/* basic stack manipulation */

int64_t   (lua_gettop) (lua_State *L);
void  (lua_settop) (lua_State *L, int64_t idx);
void  (lua_pushvalue) (lua_State *L, int64_t idx);
void  (lua_remove) (lua_State *L, int64_t idx);
void  (lua_insert) (lua_State *L, int64_t idx);
void  (lua_replace) (lua_State *L, int64_t idx);
int64_t   (lua_checkstack) (lua_State *L, int64_t sz);
void  (lua_xmove) (lua_State *from, lua_State *to, int64_t n);
void  (lua_setglobal) (lua_State *L, const char *name);
int64_t   (lua_getglobal) (lua_State *L, const char *name);
void  (lua_setglobal) (lua_State *L, const char *name);
void  (lua_pushcclosure) (lua_State *L, lua_CFunction fn, int64_t n);

/* access functions (stack -> C) */

int64_t             (lua_isnumber) (lua_State *L, int64_t idx);
int64_t             (lua_isstring) (lua_State *L, int64_t idx);
int64_t             (lua_iscfunction) (lua_State *L, int64_t idx);
int64_t             (lua_isuserdata) (lua_State *L, int64_t idx);
int64_t             (lua_type) (lua_State *L, int64_t idx);
const char     *(lua_typename) (lua_State *L, int64_t tp);

int64_t            (lua_equal) (lua_State *L, int64_t idx1, int64_t idx2);
int64_t            (lua_rawequal) (lua_State *L, int64_t idx1, int64_t idx2);
int64_t            (lua_lessthan) (lua_State *L, int64_t idx1, int64_t idx2);

lua_Number      (lua_tonumber) (lua_State *L, int64_t idx);
lua_Integer     (lua_tointeger) (lua_State *L, int64_t idx);
int64_t             (lua_toboolean) (lua_State *L, int64_t idx);
const char     *(lua_tolstring) (lua_State *L, int64_t idx, size_t *len);
size_t          (lua_objlen) (lua_State *L, int64_t idx);
lua_CFunction   (lua_tocfunction) (lua_State *L, int64_t idx);
void	         *(lua_touserdata) (lua_State *L, int64_t idx);
lua_State      *(lua_tothread) (lua_State *L, int64_t idx);
const void     *(lua_topointer) (lua_State *L, int64_t idx);

/* push functions (C -> stack) */

void  (lua_pushnil) (lua_State *L);
void  (lua_pushnumber) (lua_State *L, lua_Number n);
void  (lua_pushinteger) (lua_State *L, lua_Integer n);
void  (lua_pushlstring) (lua_State *L, const char *s, size_t l);
void  (lua_pushstring) (lua_State *L, const char *s);
const char *(lua_pushvfstring) (lua_State *L, const char *fmt,
                                                      va_list argp);
const char *(lua_pushfstring) (lua_State *L, const char *fmt, ...);
void  (lua_pushcclosure) (lua_State *L, lua_CFunction fn, int64_t n);
void  (lua_pushboolean) (lua_State *L, int64_t b);
void  (lua_pushlightuserdata) (lua_State *L, void *p);
int64_t   (lua_pushthread) (lua_State *L);

/* get functions (Lua -> stack) */

void  (lua_gettable) (lua_State *L, int64_t idx);
void  (lua_getfield) (lua_State *L, int64_t idx, const char *k);
void  (lua_rawget) (lua_State *L, int64_t idx);
void  (lua_rawgeti) (lua_State *L, int64_t idx, int64_t n);
void  (lua_createtable) (lua_State *L, int64_t narr, int64_t nrec);
void *(lua_newuserdata) (lua_State *L, size_t sz);
int64_t   (lua_getmetatable) (lua_State *L, int64_t objindex);
void  (lua_getfenv) (lua_State *L, int64_t idx);

/* set functions (stack -> Lua) */

void  (lua_settable) (lua_State *L, int64_t idx);
void  (lua_setfield) (lua_State *L, int64_t idx, const char *k);
void  (lua_rawset) (lua_State *L, int64_t idx);
void  (lua_rawseti) (lua_State *L, int64_t idx, int64_t n);
int64_t   (lua_setmetatable) (lua_State *L, int64_t objindex);
int64_t   (lua_setfenv) (lua_State *L, int64_t idx);


/* `load' and `call' functions (load and run Lua code) */
typedef ptrdiff_t lua_KContext;
typedef int64_t (*lua_KFunction) (lua_State *L, int64_t status, lua_KContext ctx);

void  (lua_call) (lua_State *L, int64_t nargs, int64_t nresults);
int64_t   (lua_pcallk) (lua_State *L, int64_t nargs, int64_t nresults, int64_t errfunc, lua_KContext ctx, lua_KFunction k);
int64_t   (lua_cpcall) (lua_State *L, lua_CFunction func, void *ud);
int64_t   (lua_load) (lua_State *L, lua_Reader reader, void *dt,
                                        const char *chunkname);

int64_t (lua_dump) (lua_State *L, lua_Writer writer, void *data);


/*  coroutine functions */

int64_t  (lua_yield) (lua_State *L, int64_t nresults);
int64_t  (lua_resume) (lua_State *L, int64_t narg);
int64_t  (lua_status) (lua_State *L);

/* garbage-collection function */

int64_t (lua_gc) (lua_State *L, int64_t what, int64_t data);

/* miscellaneous functions */

int64_t   (lua_error) (lua_State *L);
int64_t   (lua_next) (lua_State *L, int64_t idx);
void  (lua_concat) (lua_State *L, int64_t n);

enum {
/* extra error code for `luaL_load' */
	LUA_ERRFILE = (LUA_ERRERR+1),
/* pre-defined references */
	LUA_NOREF = (-2),
	LUA_REFNIL = (-1),
};
typedef struct luaL_Reg {
  const char *name;
  lua_CFunction func;
} luaL_Reg;
void (luaL_register) (lua_State *L, const char *libname,
                                const luaL_Reg *l);
int64_t (luaL_getmetafield) (lua_State *L, int64_t obj, const char *e);
int64_t (luaL_callmeta) (lua_State *L, int64_t obj, const char *e);
int64_t (luaL_typerror) (lua_State *L, int64_t narg, const char *tname);
int64_t (luaL_argerror) (lua_State *L, int64_t numarg, const char *extramsg);
const char *(luaL_checklstring) (lua_State *L, int64_t numArg,
                                                          size_t *l);
const char *(luaL_optlstring) (lua_State *L, int64_t numArg,
                                          const char *def, size_t *l);
lua_Number (luaL_checknumber) (lua_State *L, int64_t numArg);
lua_Number (luaL_optnumber) (lua_State *L, int64_t nArg, lua_Number def);
lua_Integer (luaL_checkinteger) (lua_State *L, int64_t numArg);
lua_Integer (luaL_optinteger) (lua_State *L, int64_t nArg,
                                          lua_Integer def);
void (luaL_checkstack) (lua_State *L, int64_t sz, const char *msg);
void (luaL_checktype) (lua_State *L, int64_t narg, int64_t t);
void (luaL_checkany) (lua_State *L, int64_t narg);
int64_t   (luaL_newmetatable) (lua_State *L, const char *tname);
void *(luaL_checkudata) (lua_State *L, int64_t ud, const char *tname);
void (luaL_where) (lua_State *L, int64_t lvl);
int64_t (luaL_error) (lua_State *L, const char *fmt, ...);
int64_t (luaL_checkoption) (lua_State *L, int64_t narg, const char *def,
                                   const char *const lst[]);
int64_t (luaL_ref) (lua_State *L, int64_t t);
void (luaL_unref) (lua_State *L, int64_t t, int64_t ref);
int64_t (luaL_loadfile) (lua_State *L, const char *filename);
int64_t (luaL_loadbuffer) (lua_State *L, const char *buff, size_t sz,
                                  const char *name);
int64_t (luaL_loadstring) (lua_State *L, const char *s);
lua_State *(luaL_newstate) (void);
const char *(luaL_gsub) (lua_State *L, const char *s, const char *p,
                                                  const char *r);
/* lualib.h -------------------------------------------------------- */
/* open all previous libraries */
void (luaL_openlibs) (lua_State *L);
]]
return ffi.load("bin/lua54")
