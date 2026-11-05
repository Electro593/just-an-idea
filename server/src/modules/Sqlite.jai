Primary_Result :: enum {
	OK         :: 0;    /* Successful result */
	ERROR      :: 1;    /* Generic error */
	INTERNAL   :: 2;    /* Internal logic error in SQLite */
	PERM       :: 3;    /* Access permission denied */
	ABORT      :: 4;    /* Callback routine requested an abort */
	BUSY       :: 5;    /* The database file is locked */
	LOCKED     :: 6;    /* A table in the database is locked */
	NOMEM      :: 7;    /* A malloc() failed */
	READONLY   :: 8;    /* Attempt to write a readonly database */
	INTERRUPT  :: 9;    /* Operation terminated by sqlite3_interrupt()*/
	IOERR      :: 10;   /* Some kind of disk I/O error occurred */
	CORRUPT    :: 11;   /* The database disk image is malformed */
	NOTFOUND   :: 12;   /* Unknown opcode in sqlite3_file_control() */
	FULL       :: 13;   /* Insertion failed because database is full */
	CANTOPEN   :: 14;   /* Unable to open the database file */
	PROTOCOL   :: 15;   /* Connection lock protocol error */
	EMPTY      :: 16;   /* No content */
	SCHEMA     :: 17;   /* The database schema changed */
	TOOBIG     :: 18;   /* String or BLOB exceeds size limit */
	CONSTRAINT :: 19;   /* Abort due to constraint violation */
	MISMATCH   :: 20;   /* Data type mismatch */
	MISUSE     :: 21;   /* Library used incorrectly */
	NOLFS      :: 22;   /* Uses OS features not supported on host */
	AUTH       :: 23;   /* Authorization denied */
	FORMAT     :: 24;   /* Not used */
	RANGE      :: 25;   /* 2nd parameter to sqlite3_bind out of range */
	NOTADB     :: 26;   /* File opened that is not a database file */
	NOTICE     :: 27;   /* Notifications from sqlite3_log() */
	WARNING    :: 28;   /* Warnings from sqlite3_log() */
	ROW        :: 100;  /* sqlite3_step() has another row ready */
	DONE       :: 101;  /* sqlite3_step() has finished executing */
}

Result :: enum {
	using Primary_Result;

	OK_LOAD_PERMANENTLY :: OK | 1 << 8;
	OK_SYMLINK          :: OK | 2 << 8;  /* internal only */

	ERROR_MISSING_COLLSEQ :: ERROR | 1 << 8;
	ERROR_RETRY           :: ERROR | 2 << 8;
	ERROR_SNAPSHOT        :: ERROR | 3 << 8;
	ERROR_RESERVESIZE     :: ERROR | 4 << 8;
	ERROR_KEY             :: ERROR | 5 << 8;
	ERROR_UNABLE          :: ERROR | 6 << 8;

	ABORT_ROLLBACK :: ABORT | 2 << 8;

	BUSY_RECOVERY :: BUSY | 1 << 8;
	BUSY_SNAPSHOT :: BUSY | 2 << 8;
	BUSY_TIMEOUT  :: BUSY | 3 << 8;

	LOCKED_SHAREDCACHE :: LOCKED | 1 << 8;
	LOCKED_VTAB        :: LOCKED | 2 << 8;

	READONLY_RECOVERY  :: READONLY | 1 << 8;
	READONLY_CANTLOCK  :: READONLY | 2 << 8;
	READONLY_ROLLBACK  :: READONLY | 3 << 8;
	READONLY_DBMOVED   :: READONLY | 4 << 8;
	READONLY_CANTINIT  :: READONLY | 5 << 8;
	READONLY_DIRECTORY :: READONLY | 6 << 8;

	IOERR_READ              :: IOERR |  1 << 8;
	IOERR_SHORT_READ        :: IOERR |  2 << 8;
	IOERR_WRITE             :: IOERR |  3 << 8;
	IOERR_FSYNC             :: IOERR |  4 << 8;
	IOERR_DIR_FSYNC         :: IOERR |  5 << 8;
	IOERR_TRUNCATE          :: IOERR |  6 << 8;
	IOERR_FSTAT             :: IOERR |  7 << 8;
	IOERR_UNLOCK            :: IOERR |  8 << 8;
	IOERR_RDLOCK            :: IOERR |  9 << 8;
	IOERR_DELETE            :: IOERR | 10 << 8;
	IOERR_BLOCKED           :: IOERR | 11 << 8;
	IOERR_NOMEM             :: IOERR | 12 << 8;
	IOERR_ACCESS            :: IOERR | 13 << 8;
	IOERR_CHECKRESERVEDLOCK :: IOERR | 14 << 8;
	IOERR_LOCK              :: IOERR | 15 << 8;
	IOERR_CLOSE             :: IOERR | 16 << 8;
	IOERR_DIR_CLOSE         :: IOERR | 17 << 8;
	IOERR_SHMOPEN           :: IOERR | 18 << 8;
	IOERR_SHMSIZE           :: IOERR | 19 << 8;
	IOERR_SHMLOCK           :: IOERR | 20 << 8;
	IOERR_SHMMAP            :: IOERR | 21 << 8;
	IOERR_SEEK              :: IOERR | 22 << 8;
	IOERR_DELETE_NOENT      :: IOERR | 23 << 8;
	IOERR_MMAP              :: IOERR | 24 << 8;
	IOERR_GETTEMPPATH       :: IOERR | 25 << 8;
	IOERR_CONVPATH          :: IOERR | 26 << 8;
	IOERR_VNODE             :: IOERR | 27 << 8;
	IOERR_AUTH              :: IOERR | 28 << 8;
	IOERR_BEGIN_ATOMIC      :: IOERR | 29 << 8;
	IOERR_COMMIT_ATOMIC     :: IOERR | 30 << 8;
	IOERR_ROLLBACK_ATOMIC   :: IOERR | 31 << 8;
	IOERR_DATA              :: IOERR | 32 << 8;
	IOERR_CORRUPTFS         :: IOERR | 33 << 8;
	IOERR_IN_PAGE           :: IOERR | 34 << 8;
	IOERR_BADKEY            :: IOERR | 35 << 8;
	IOERR_CODEC             :: IOERR | 36 << 8;

	CORRUPT_VTAB     :: CORRUPT | 1 << 8;
	CORRUPT_SEQUENCE :: CORRUPT | 2 << 8;
	CORRUPT_INDEX    :: CORRUPT | 3 << 8;

	CANTOPEN_NOTEMPDIR :: CANTOPEN | 1 << 8;
	CANTOPEN_ISDIR     :: CANTOPEN | 2 << 8;
	CANTOPEN_FULLPATH  :: CANTOPEN | 3 << 8;
	CANTOPEN_CONVPATH  :: CANTOPEN | 4 << 8;
	CANTOPEN_DIRTYWAL  :: CANTOPEN | 5 << 8;  /* Not Used */
	CANTOPEN_SYMLINK   :: CANTOPEN | 6 << 8;

	CONSTRAINT_CHECK      :: CONSTRAINT |  1 << 8;
	CONSTRAINT_COMMITHOOK :: CONSTRAINT |  2 << 8;
	CONSTRAINT_FOREIGNKEY :: CONSTRAINT |  3 << 8;
	CONSTRAINT_FUNCTION   :: CONSTRAINT |  4 << 8;
	CONSTRAINT_NOTNULL    :: CONSTRAINT |  5 << 8;
	CONSTRAINT_PRIMARYKEY :: CONSTRAINT |  6 << 8;
	CONSTRAINT_TRIGGER    :: CONSTRAINT |  7 << 8;
	CONSTRAINT_UNIQUE     :: CONSTRAINT |  8 << 8;
	CONSTRAINT_VTAB       :: CONSTRAINT |  9 << 8;
	CONSTRAINT_ROWID      :: CONSTRAINT | 10 << 8;
	CONSTRAINT_PINNED     :: CONSTRAINT | 11 << 8;
	CONSTRAINT_DATATYPE   :: CONSTRAINT | 12 << 8;

	AUTH_USER :: AUTH | 1 << 8;

	NOTICE_RECOVER_WAL      :: NOTICE | 1 << 8;
	NOTICE_RECOVER_ROLLBACK :: NOTICE | 2 << 8;
	NOTICE_RBU              :: NOTICE | 3 << 8;

	WARNING_AUTOINDEX :: WARNING | 1 << 8;
}

Value_Type :: enum {
	INTEGER :: 1;
	FLOAT   :: 2;
	TEXT    :: 3;
	BLOB    :: 4;
	NULL    :: 5;
}

Lifetime :: enum {
	TRANSIENT :: -1;
	STATIC    :: 0;
	// Any other value is .DESTRUCTOR, created via destructor(callback)
}

Text_Encoding :: enum {
	UTF8          ::  1;  /* IMP: R-37514-35566 */
	UTF16LE       ::  2;  /* IMP: R-03371-37637 */
	UTF16BE       ::  3;  /* IMP: R-51971-34154 */
	UTF16         ::  4;  /* Use native byte order */
	ANY           ::  5;  /* Deprecated */
	UTF16_ALIGNED ::  8;  /* sqlite3_create_collation only */
	UTF8_ZT       :: 16;  /* Zero-terminated UTF8 */
}

Carray_Bind_Flags :: enum_flags {
	INT32  :: 0;  /* Data is [] s32 */
	INT64  :: 1;  /* Data is [] s64 */
	DOUBLE :: 2;  /* Data is [] float64 */
	TEXT   :: 3;  /* Data is [] *u8 */
	BLOB   :: 4;  /* Data is [] iovec */
}

Prepare_Flags :: enum_flags {
	PERSISTENT :: 1 << 0;
	NORMALIZE  :: 1 << 1;
	NO_VTAB    :: 1 << 2;
	DONT_LOG   :: 1 << 4;
	FROM_DDL   :: 1 << 5;
}

Open_Flags :: enum_flags {
	READONLY      :: 1 <<  0;  /* Ok for sqlite3_open_v2() */
	READWRITE     :: 1 <<  1;  /* Ok for sqlite3_open_v2() */
	CREATE        :: 1 <<  2;  /* Ok for sqlite3_open_v2() */
	DELETEONCLOSE :: 1 <<  3;  /* VFS only */
	EXCLUSIVE     :: 1 <<  4;  /* VFS only */
	AUTOPROXY     :: 1 <<  5;  /* VFS only */
	URI           :: 1 <<  6;  /* Ok for sqlite3_open_v2() */
	MEMORY        :: 1 <<  7;  /* Ok for sqlite3_open_v2() */
	MAIN_DB       :: 1 <<  8;  /* VFS only */
	TEMP_DB       :: 1 <<  9;  /* VFS only */
	TRANSIENT_DB  :: 1 << 10;  /* VFS only */
	MAIN_JOURNAL  :: 1 << 11;  /* VFS only */
	TEMP_JOURNAL  :: 1 << 12;  /* VFS only */
	SUBJOURNAL    :: 1 << 13;  /* VFS only */
	SUPER_JOURNAL :: 1 << 14;  /* VFS only */
	NOMUTEX       :: 1 << 15;  /* Ok for sqlite3_open_v2() */
	FULLMUTEX     :: 1 << 16;  /* Ok for sqlite3_open_v2() */
	SHAREDCACHE   :: 1 << 17;  /* Ok for sqlite3_open_v2() */
	PRIVATECACHE  :: 1 << 18;  /* Ok for sqlite3_open_v2() */
	WAL           :: 1 << 19;  /* VFS only */
	NOFOLLOW      :: 1 << 24;  /* Ok for sqlite3_open_v2() */
	EXRESCODE     :: 1 << 25;  /* Extended result codes */
}

Api_Routines :: struct {}
Backup :: struct {}
Blob :: struct {}
Context :: struct {}
Connection :: struct {}
Statement :: struct {}
Value :: struct {}

Auto_Vacuum_Pages_Callback :: #type (param: *void, schema: *u8, num_database_pages: u32, num_free_pages: u32, num_bytes_per_page: u32) -> (num_free_pages_to_remove: u32) #c_call;
Busy_Handler_Callback :: #type (param: *void, num_previous_attempts: s32) -> (try_again: bool) #c_call;
Collation_Needed_Callback :: #type (param: *void, connection: *Connection, encoding: Text_Encoding, collation_name: *u8) -> () #c_call;
Collation_Needed16_Callback :: #type (param: *void, connection: *Connection, encoding: Text_Encoding, collation_name: *u16) -> () #c_call;
Commit_Hook_Callback :: #type (param: *void) -> (should_rollback: bool) #c_call;
Destructor_Callback :: #type (param_to_destroy: *void) -> () #c_call;
Extension_Entry_Point_Callback :: #type (connection: *Connection, error_message_out: **u8, api_thunk: *Api_Routines) -> (result: Result) #c_call;
Rollback_Hook_Callback :: #type (param: *void) -> () #c_call;

destructor :: (destructor: Destructor_Callback) -> Lifetime {
	return xx cast(*void) destructor;
}

open :: (filename: string) -> (result: Result, connection: *Connection) {
	connection: *Connection;
	result := sqlite3_open_v2(
		filename,
		*connection,
		.READWRITE | .CREATE | .EXRESCODE,
		null
	);

	if result != .OK {
		sqlite3_close(connection);
		return result, null;
	}

	return .OK, connection;
}

close :: (connection: *Connection) -> Result {
	sqlite3_close(connection);
}

prepare :: (connection: *Connection, sql: string, cached := false) -> (result: Result, statement: *Statement = null, sql_remainder := "") {
	statement: *Statement = ---;
	sql_remainder: *u8 = ---;

	result := sqlite3_prepare_v3(
		connection,
		sql.data,
		xx sql.count,
		ifx cached then .PERSISTENT else 0,
		*statement,
		*sql_remainder
	);
	if result != .OK return result;

	return result, statement, to_string(sql_remainder);
}

bind :: (statement: *Statement, params: Any, index: s32 = 1) -> Result {
	count := sqlite3_bind_parameter_count(statement);
	if (count == 0) return .OK;

	any := unwrap_any(params);
	type := any.type;
	ptr := any.value_pointer;

	if type.type == {
	case .PROCEDURE;
		// FUTURE: Could allow dynamic evaluation here
		return .MISUSE;

	case .STRUCT;
		info: *Type_Info_Struct = xx params.type;
		for info.members {
			elem_ptr := ptr + it.offset_in_bytes;
			new_params := Any.{ type = it.type, value_pointer = elem_ptr };
			named_index := sqlite3_bind_parameter_index(statement, it.name.data);
			if named_index > 0 && named_index <= count {
				result := bind_primitive(statement, named_index, new_params);
				if result != .OK return result;
			}
		}
		return .OK;

	case .ARRAY;
		info: *Type_Info_Array = xx params.type;
		value := (.*) cast(*[] void) ptr;
		for 0 .. value.count - 1 {
			elem_ptr := value.data + info.element_type.runtime_size * it;
			new_params := Any.{ type = info.element_type, value_pointer = elem_ptr };
			elem_index := cast(s32) (it + index);
			if elem_index <= count {
				result := bind_primitive(statement, elem_index, new_params);
				if result != .OK return result;
			}
		}
		return .OK;
	}

	return bind_primitive(statement, index, params);
}

column :: (
	statement: *Statement,
	column_index: int,
	$T: Type
) -> (value: T, result: Result) #expand {
	value: T;
	result := column(statement, column_index, *value);
	return value, result;
}

column :: (
	statement: *Statement,
	column_index: int,
	value: *$T
) -> Result
#modify {
	if (cast(*Type_Info) T).type == {
	case .INTEGER; return true;
	case .FLOAT; return true;
	case .BOOL; return true;
	case .STRING; return true;
	case .POINTER; return true;
	case .STRUCT; return true;
	case .ARRAY; return true;
	case .ANY; return true;
	case .ENUM; return true;
	case .VARIANT; return true;
	case; return false;
	}
}
#expand {
	column_blob :: (
		statement: *Statement,
		column_index: int
	) -> (data: [] u8, result: Result) {
		connection := sqlite3_db_handle(statement);
		data := sqlite3_column_blob(statement, xx column_index);
		result := sqlite3_errcode(connection);
		if data == null then return .[], result;

		count := sqlite3_column_bytes(statement, xx column_index);
		result = sqlite3_errcode(connection);
		if result != .OK then return .[], result;

		return .{ data = data, count = count }, .OK;
	}

	#if type_info(T).type == {
	case .INTEGER;
		value.* = xx sqlite3_column_int64(statement, xx column_index);

	case .FLOAT;
		value.* = xx sqlite3_column_double(statement, xx column_index);

	case .BOOL;
		value.* = xx sqlite3_column_int(statement, xx column_index);

	case .STRING;
		value.* = "";
		connection := sqlite3_db_handle(statement);
		data := sqlite3_column_text(statement, xx column_index);
		result := sqlite3_errcode(connection);
		if data == null then return result;

		count := sqlite3_column_bytes(statement, xx column_index);
		result = sqlite3_errcode(connection);
		if result != .OK then return result;

		value.* = .{ data = alloc(value.count), count = count };
		if value.data == null then return .NOMEM;
		memcpy(value.data, data, value.count);

	case .POINTER;
		info: *Type_Info_Pointer = xx type_info(T);

		column_type := sqlite3_column_type(statement, xx column_index);
		if column_type == .NULL {
			value.* = null;
			return .OK;
		}

		size := info.pointer_to.runtime_size;
		value.* = alloc(size);
		if value.* == null then return .NOMEM;
		return column(statement, column_index, value.*);

	case .STRUCT;
		info: *Type_Info_Struct = xx type_info(T);
		data, result := column_blob(statement, column_index);
		if data.data == null || result != .OK {
			Initialize(value);
			return result;
		}

		size := info.runtime_size;
		if size > data.count {
			size = data.count;
			Initialize(value);
		}

		memcpy(value, data.data, size);

	case .ARRAY;
		info: *Type_Info_Array = xx type_info(T);
		value.* = .[];

		data, result := column_blob(statement, column_index);
		if data.data == null || result != .OK then return result;

		element_size := info.element_type.runtime_size;
		if element_size < 1 then element_size = 1;
		count := (data.count + element_size - 1) / element_size;
		size := count * element_size;
		value.data = alloc(size);
		if value.data == null then return .NOMEM;
		value.count = count;

		memcpy(value.data, data.data, data.count);
		if size != data.count
			memset(cast(*u8) value.data + data.count, 0, size - data.count);

	case .ANY;
		column_type := sqlite3_column_type(statement, xx column_index);
		result := Result.OK;

		if #complete column_type == {
		case .INTEGER;
			value.type = type_info(int);
			return column(statement, column_index, cast(*int) value.value_pointer);

		case .FLOAT;
			value.type = type_info(float);
			return column(statement, column_index, cast(*float) value.value_pointer);

		case .TEXT;
			value.type = type_info(string);
			return column(statement, column_index, cast(*string) value.value_pointer);

		case .BLOB;
			value.type = type_info([] u8);
			return xx column(statement, column_index, cast(*[] u8) value.value_pointer);

		case .NULL;
			value.* = Any.{};
		}

	case .ENUM;
		B :: #run unwrap_enum(T);
		return column(statement, column_index, cast(*B) value);

	case .VARIANT;
		B :: #run unwrap_variants(T);
		return column(statement, column_index, cast(*B) value);

	case; #assert false;
	}

	return .OK;
}

exec :: (connection: *Connection, sql: string) -> Result {
	remainder := sql;

	while remainder.count > 0 {
		result:, statement:, remainder = prepare(connection, remainder);
		if result != .OK return result;
		if statement == null continue;

		result = sqlite3_step(statement);
		while result == .ROW
			result = sqlite3_step(statement);

		if result != .DONE {
			sqlite3_finalize(statement);
			return result;
		}
	}

	return .OK;
}

exec :: (
	connection: *Connection,
	sql: string,
	params := Any.{},
	mapper: (statement: *Statement) -> $T = null,
	cached_statement: **Statement = null
) -> (result: Result, rows: [] T = .[]) {
	cached := cached_statement != null;
	statement := ifx cached then cached_statement.* else null;
	result := Result.OK;
	remainder := "";

	if statement == null {
		result, statement, remainder = prepare(connection, sql, cached = cached);
		if result != .OK return result;
		if cached then cached_statement.* = statement;
		assert(statement != null, "Statement was empty");
		assert(remainder == "", "Cannot execute multiple cached or result-set statements");
	} else {
		result = sqlite3_clear_bindings(statement);
		if result != .OK return result;
	}

	defer {
		exit_result := Result.OK;
		if cached
			exit_result := sqlite3_reset(statement);
		else
			exit_result := sqlite3_finalize(statement);
		if result == .OK && exit_result != .OK return exit_result;
	}

	result = bind(statement, params);
	if result != .OK return result;

	result = .ROW;
	rows: [..] T;
	while result == .ROW {
		row: T;
		result := sqlite3_step(statement);

		if result == .DONE then result = .OK;
		if result == .ROW && mapper != null {
			array_add(*rows, mapper(statement));
		}
	}

	if result != .OK then array_free(rows);

	return result, rows;
}

finalize :: (statement: *Statement) -> Result {
	return sqlite3_finalize(statement);
}

#scope_file

unwrap_any :: (any: Any) -> Any {
	result := any;

	while true {
		if result.type.type == {
		case .VARIANT;
			info: *Type_Info_Variant = xx result.type;
			result.type = info.variant_of;

		case .ANY;
			result = (.*) cast(*Any) result.value_pointer;

		case; break;
		}
	}

	return result;
}

unwrap_enum :: (type: Type) -> Type #expand {
	info: *Type_Info_Enum = xx type_info(type);
	if info.type != .ENUM then return type;
	return (.*) cast(*Type) *info.internal_type;
}

unwrap_variants :: (type: Type) -> Type #expand {
	info: *Type_Info = xx type_info(type);
	while info.type == .VARIANT
		info = (cast(*Type_Info_Variant) info).variant_of;
	return (.*) cast(*Type) *info;
}

bind_primitive :: (statement: *Statement, index: s32, params: Any) -> Result {
	any := unwrap_any(params);
	type := any.type;
	ptr := any.value_pointer;

	if type.type == {
	case .ENUM;
		type = (cast(*Type_Info_Enum) type).internal_type;

	case .POINTER;
		value := (.*) cast(**void) ptr;
		if value == null then ptr = null;
		type = (cast(*Type_Info_Pointer) type).pointer_to;
	}

	if ptr == null
		return sqlite3_bind_null(statement, index);

	if type.type == {
	case .VOID;
		return .OK;

	case .BOOL;
		return sqlite3_bind_int(statement, index, xx (.*) cast(*bool) ptr);

	case .INTEGER;
		info: *Type_Info_Integer = xx type;
		value: s64 = ---;
		if info.signed {
			if info.runtime_size == {
			case 1; value = (.*) cast(*s8) ptr;
			case 2; value = (.*) cast(*s16) ptr;
			case 4; value = (.*) cast(*s32) ptr;
			case 8; value = (.*) cast(*s64) ptr;
			case; return .MISUSE;
			}
		} else {
			if info.runtime_size == {
			case 1; value = (.*) cast(*u8) ptr;
			case 2; value = (.*) cast(*u16) ptr;
			case 4; value = (.*) cast(*u32) ptr;
			case 8;
				value = xx (.*) cast(*u64) ptr;
				if value < 0 return .MISUSE;
			case; return .MISUSE;
			}
		}
		return sqlite3_bind_int64(statement, index, value);

	case .FLOAT;
		value: float64 = ---;
		if type.runtime_size == {
		case 4; value = (.*) cast(*float32) ptr;
		case 8; value = (.*) cast(*float64) ptr;
		case; return .MISUSE;
		}
		return sqlite3_bind_double(statement, index, value);

	case .STRING;
		// FUTURE: Wide chars, custom lifetimes
		value := (.*) cast(*string) ptr;
		if value.count < 0 return .MISUSE;
		encoding: Encoding = ifx value.data && !value.data[value.count] then .UTF8_ZT else .UTF8;
		return sqlite3_bind_text64(statement, index, value.data, xx value.count, .STATIC, encoding);

	case .ARRAY;
		// FUTURE: Zero-blobs, custom lifetime
		info: *Type_Info_Array = xx type;
		value := (.*) cast(*[] void) ptr;
		if value.count < 0 return .MISUSE;
		size := cast(u64) value.count * xx info.element_type.runtime_size;
		return sqlite3_bind_blob64(statement, index, value.data, size, .STATIC);

	case .STRUCT;
		// FUTURE: Could allow value- or pointer- passing here, plus custom lifetime
		return sqlite3_bind_blob64(statement, index, ptr, xx type.runtime_size, .TRANSIENT);
	}

	return .MISUSE;
}

libsqlite3 :: #library,system "libsqlite3";

sqlite3_aggregate_context :: (function_context: *Context, num_bytes_to_allocate: s32) -> (context_buffer: *void) #foreign libsqlite3;
sqlite3_auto_extension :: (entry_point: Extension_Entry_Point_Callback) -> (result: Result) #foreign libsqlite3;
sqlite3_autovacuum_pages :: (connection: *Connection, callback: Auto_Vacuum_Pages_Callback, param: *void, param_lifetime: Lifetime) -> (result: Result) #foreign libsqlite3;
sqlite3_backup_finish :: (backup: *Backup) -> (result: Result) #foreign libsqlite3;
sqlite3_backup_init :: (destination_connection: *Connection, destination_database_name: *u8, source_connection: *Connection, source_database_name: *u8) -> (backup: *Backup) #foreign libsqlite3;
sqlite3_backup_pagecount :: (backup: *Backup) -> (num_source_pages: s32) #foreign libsqlite3;
sqlite3_backup_remaining :: (backup: *Backup) -> (num_pages_to_copy: s32) #foreign libsqlite3;
sqlite3_backup_step :: (backup: *Backup, num_pages_to_copy: s32) -> (result: Result) #foreign libsqlite3;
sqlite3_bind_blob :: (statement: *Statement, param_index: s32, value: *void, num_bytes: s32, value_lifetime: Lifetime) -> (result: Result) #foreign libsqlite3;
sqlite3_bind_blob64 :: (statement: *Statement, param_index: s32, value: *void, num_bytes: u64, value_lifetime: Lifetime) -> (result: Result) #foreign libsqlite3;
sqlite3_bind_double :: (statement: *Statement, param_index: s32, value: float64) -> (result: Result) #foreign libsqlite3;
sqlite3_bind_int :: (statement: *Statement, param_index: s32, value: s32) -> (result: Result) #foreign libsqlite3;
sqlite3_bind_int64 :: (statement: *Statement, param_index: s32, value: s64) -> (result: Result) #foreign libsqlite3;
sqlite3_bind_null :: (statement: *Statement, param_index: s32) -> (result: Result) #foreign libsqlite3;
sqlite3_bind_parameter_count :: (statement: *Statement) -> (num_params: s32) #foreign libsqlite3;
sqlite3_bind_parameter_index :: (statement: *Statement, param_name: *u8) -> (param_index: s32) #foreign libsqlite3;
sqlite3_bind_parameter_name :: (statement: *Statement, param_index: s32) -> (param_name: *u8) #foreign libsqlite3;
sqlite3_bind_pointer :: (statement: *Statement, param_index: s32, value: *void, type: *u8, lifetime: Lifetime) -> (result: Result) #foreign libsqlite3;
sqlite3_bind_text :: (statement: *Statement, param_index: s32, value: *u8, num_bytes: s32, value_lifetime: Lifetime) -> (result: Result) #foreign libsqlite3;
sqlite3_bind_text16 :: (statement: *Statement, param_index: s32, value: *u16, num_bytes: s32, value_lifetime: Lifetime) -> (result: Result) #foreign libsqlite3;
sqlite3_bind_text64 :: (statement: *Statement, param_index: s32, value: *u8, num_bytes: u64, value_lifetime: Lifetime, text_encoding: Text_Encoding) -> (result: Result) #foreign libsqlite3;
sqlite3_bind_value :: (statement: *Statement, param_index: s32, value: *Value) -> (result: Result) #foreign libsqlite3;
sqlite3_bind_zeroblob :: (statement: *Statement, param_index: s32, num_bytes: s32) -> (result: Result) #foreign libsqlite3;
sqlite3_bind_zeroblob64 :: (statement: *Statement, param_index: s32, num_bytes: u64) -> (result: Result) #foreign libsqlite3;
sqlite3_blob_bytes :: (blob: *Blob) -> (num_bytes: s32) #foreign libsqlite3;
sqlite3_blob_close :: (blob: *Blob) -> (result: Result) #foreign libsqlite3;
sqlite3_blob_open :: (connection: *Connection, database_name: *u8, table_name: *u8, column_name: *u8, row_id: s64, is_writable: bool, blob_out: **Blob) -> (result: Result) #foreign libsqlite3;
sqlite3_blob_read :: (blob: *Blob, destination_buffer: *void, num_bytes_to_read: s32, offset_from_start: s32) -> (result: Result) #foreign libsqlite3;
sqlite3_blob_reopen :: (blob: *Blob, row_id_to_open: s64) -> (result: Result) #foreign libsqlite3;
sqlite3_blob_write :: (blob: *Blob, source_buffer: *void, num_bytes_to_write: s32, offset_from_start: s32) -> (result: Result) #foreign libsqlite3;
sqlite3_busy_handler :: (connection: *Connection, callback: Busy_Handler_Callback, param: *void) -> (result: Result) #foreign libsqlite3;
sqlite3_busy_timeout :: (connection: *Connection, timeout_milliseconds: s32) -> (result: Result) #foreign libsqlite3;
sqlite3_cancel_auto_extension :: (entry_point: Extension_Entry_Point_Callback) -> (was_previously_registered: bool) #foreign libsqlite3;
// sqlite3_carray_bind :: (statement: *Statement, param_index: s32, array_data: *void, array_count: s32, flags: Carray_Bind_Flags, data_lifetime: Lifetime) -> (result: Result) #foreign libsqlite3;
// sqlite3_carray_bind_v2 :: (statement: *Statement, param_index: s32, array_data: *void, array_count: s32, flags: Carray_Bind_Flags, data_lifetime: Lifetime, destructor_param: *void) -> (result: Result) #foreign libsqlite3;
sqlite3_changes :: (connection: *Connection) -> (num_rows_changed: s32) #foreign libsqlite3;
sqlite3_changes64 :: (connection: *Connection) -> (num_rows_changed: s64) #foreign libsqlite3;
sqlite3_clear_bindings :: (statement: *Statement) -> (result: Result) #foreign libsqlite3;
sqlite3_close :: (connection: *Connection) -> (result: Result) #foreign libsqlite3;
sqlite3_close_v2 :: (connection: *Connection) -> (result: Result) #foreign libsqlite3;
sqlite3_collation_needed :: (connection: *Connection, param: *void, callback: Collation_Needed_Callback) -> (result: Result) #foreign libsqlite3;
sqlite3_collation_needed16 :: (connection: *Connection, param: *void, callback: Collation_Needed16_Callback) -> (result: Result) #foreign libsqlite3;
sqlite3_column_blob :: (statement: *Statement, column_index: s32) -> (value: *void) #foreign libsqlite3;
sqlite3_column_bytes :: (statement: *Statement, column_index: s32) -> (num_bytes: s32) #foreign libsqlite3;
sqlite3_column_bytes16 :: (statement: *Statement, column_index: s32) -> (num_bytes: s32) #foreign libsqlite3;
sqlite3_column_count :: (statement: *Statement) -> (num_columns: s32) #foreign libsqlite3;
sqlite3_column_database_name :: (statement: *Statement, column_index: s32) -> (origin_database_name: *u8) #foreign libsqlite3;
sqlite3_column_database_name16 :: (statement: *Statement, column_index: s32) -> (origin_database_name: *u16) #foreign libsqlite3;
sqlite3_column_decltype :: (statement: *Statement, column_index: s32) -> (declared_type_name: *u8) #foreign libsqlite3;
sqlite3_column_decltype16 :: (statement: *Statement, column_index: s32) -> (declared_type_name: *u16) #foreign libsqlite3;
sqlite3_column_double :: (statement: *Statement, column_index: s32) -> (value: float64) #foreign libsqlite3;
sqlite3_column_int :: (statement: *Statement, column_index: s32) -> (value: s32) #foreign libsqlite3;
sqlite3_column_int64 :: (statement: *Statement, column_index: s32) -> (value: s64) #foreign libsqlite3;
sqlite3_column_name :: (statement: *Statement, column_index: s32) -> (column_name: *u8) #foreign libsqlite3;
sqlite3_column_name16 :: (statement: *Statement, column_index: s32) -> (column_name: *u16) #foreign libsqlite3;
sqlite3_column_origin_name :: (statement: *Statement, column_index: s32) -> (origin_column_name: *u8) #foreign libsqlite3;
sqlite3_column_origin_name16 :: (statement: *Statement, column_index: s32) -> (origin_column_name: *u16) #foreign libsqlite3;
sqlite3_column_table_name :: (statement: *Statement, column_index: s32) -> (origin_table_name: *u8) #foreign libsqlite3;
sqlite3_column_table_name16 :: (statement: *Statement, column_index: s32) -> (origin_table_name: *u16) #foreign libsqlite3;
sqlite3_column_text :: (statement: *Statement, column_index: s32) -> (value: *u8) #foreign libsqlite3;
sqlite3_column_text16 :: (statement: *Statement, column_index: s32) -> (value: *u16) #foreign libsqlite3;
sqlite3_column_type :: (statement: *Statement, column_index: s32) -> (value_type: Value_Type) #foreign libsqlite3;
sqlite3_column_value :: (statement: *Statement, column_index: s32) -> (value: *Value) #foreign libsqlite3;
sqlite3_commit_hook :: (connection: *Connection, callback: Commit_Hook_Callback, param: *void) -> (previous_param: *void) #foreign libsqlite3;
sqlite3_compileoption_get :: (option_index: s32) -> (option_name: *u8) #foreign libsqlite3;
sqlite3_compileoption_used :: (option_name: *u8) -> (is_used: bool) #foreign libsqlite3;
sqlite3_complete :: (sql: *u8) -> (is_complete: bool) #foreign libsqlite3;
sqlite3_complete16 :: (sql: *u16) -> (is_complete: bool) #foreign libsqlite3;

sqlite3_ :: () -> () #foreign libsqlite3;

sqlite3_data_count :: (statement: *Statement) -> s32 #foreign libsqlite3;
sqlite3_db_handle :: (statement: *Statement) -> *Connection #foreign libsqlite3;
sqlite3_errcode :: (connection: *Connection) -> Result #foreign libsqlite3;
sqlite3_errmsg :: (connection: *Connection) -> *u8 #foreign libsqlite3;
sqlite3_errmsg16 :: (connection: *Connection) -> *u16 #foreign libsqlite3;
sqlite3_error_offset :: (connection: *Connection) -> s32 #foreign libsqlite3;
sqlite3_errstr :: (result: Result) -> *u8 #foreign libsqlite3;
sqlite3_extended_errcode :: (connection: *Connection) -> Result #foreign libsqlite3;
sqlite3_extended_result_codes :: (connection: *Connection, enabled: bool) -> Result #foreign libsqlite3;
sqlite3_finalize :: (statement: *Statement) -> Result #foreign libsqlite3;
sqlite3_incomplete :: (sql: *u16) -> (result: s64) #foreign libsqlite3; // FUTURE: Add typing for the result aggregate
sqlite3_open :: (filename: *u8, connection: **Connection) -> Result #foreign libsqlite3;
sqlite3_open16 :: (filename: *u16, connection: **Connection) -> Result #foreign libsqlite3;
sqlite3_open_v2 :: (filename: *u8, connection: **Connection, flags: Open_Flags, vfs_name: *u8) -> Result #foreign libsqlite3;
sqlite3_prepare :: (connection: *Connection, sql: *u8, size: s32, statement: **Statement, sql_tail: **u8) -> Result #foreign libsqlite3;
sqlite3_prepare_v2 :: (connection: *Connection, sql: *u8, size: s32, statement: **Statement, sql_tail: **u8) -> Result #foreign libsqlite3;
sqlite3_prepare_v3 :: (connection: *Connection, sql: *u8, size: s32, flags: Prepare_Flags, statement: **Statement, sql_tail: **u8) -> Result #foreign libsqlite3;
sqlite3_prepare16 :: (connection: *Connection, sql: *u16, size: s32, statement: **Statement, sql_tail: **u16) -> Result #foreign libsqlite3;
sqlite3_prepare16_v2 :: (connection: *Connection, sql: *u16, size: s32, statement: **Statement, sql_tail: **u16) -> Result #foreign libsqlite3;
sqlite3_prepare16_v3 :: (connection: *Connection, sql: *u16, size: s32, flags: Prepare_Flags, statement: **Statement, sql_tail: **u16) -> Result #foreign libsqlite3;
sqlite3_reset :: (statement: *Statement) -> Result #foreign libsqlite3;
sqlite3_reset_auto_extension :: () -> () #foreign libsqlite3;
sqlite3_rollback_hook :: (connection: *Connection, callback: Rollback_Hook_Callback, param: *void) -> (previous_param: *void) #foreign libsqlite3;
sqlite3_step :: (statement: *Statement) -> Result #foreign libsqlite3;

#import "Basic";
