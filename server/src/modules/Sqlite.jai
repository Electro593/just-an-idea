#module_parameters (MIGRATIONS: [] string = .[]) ();

Sqlite_Primary_Result :: enum {
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
	PROTOCOL   :: 15;   /* Database lock protocol error */
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

Sqlite_Result :: enum {
	using Sqlite_Primary_Result;

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

Sqlite_Encoding :: enum {
	UTF8          ::  1;  /* IMP: R-37514-35566 */
	UTF16LE       ::  2;  /* IMP: R-03371-37637 */
	UTF16BE       ::  3;  /* IMP: R-51971-34154 */
	UTF16         ::  4;  /* Use native byte order */
	ANY           ::  5;  /* Deprecated */
	UTF16_ALIGNED ::  8;  /* sqlite3_create_collation only */
	UTF8_ZT       :: 16;  /* Zero-terminated UTF8 */
}

Sqlite_Lifetime :: enum {
	TRANSIENT :: -1;
	STATIC    :: 0;
}

sqlite_destructor :: (destructor: (param: *void)) -> Sqlite_Lifetime {
	return xx cast(*void) destructor;
}

Sqlite_Prepare_Flags :: enum_flags {
	PERSISTENT :: 1 << 0;
	NORMALIZE  :: 1 << 1;
	NO_VTAB    :: 1 << 2;
	DONT_LOG   :: 1 << 4;
	FROM_DDL   :: 1 << 5;
}

Sqlite_Open_Flags :: enum_flags {
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

Sqlite_Type :: enum {
	INTEGER :: 1;
	FLOAT   :: 2;
	TEXT    :: 3;
	BLOB    :: 4;
	NULL    :: 5;
}

Sqlite_Database :: struct {}
Sqlite_Statement :: struct {}
Sqlite_Value :: struct {}

open :: (filename: string) -> (result: Sqlite_Result, database: *Sqlite_Database) {
	database: *Sqlite_Database;
	result := sqlite3_open_v2(filename, *database, .EXRESCODE, null);
	if result != .OK {
		sqlite3_close(database);
		return result, null;
	}

	return .OK, database;
}

column_int :: (
	statement: *Sqlite_Statement,
	column_index: int,
	$T: Type = int
) -> T
#modify {
	return (cast(*Type_Info) T).type == .INTEGER;
}
#expand {
	return xx sqlite3_column_int64(statement, xx column_index);
}

column_float :: (
	statement: *Sqlite_Statement,
	column_index: int,
	$T: Type = float
) -> float64
#modify {
	return (cast(*Type_Info) T).type == .FLOAT;
}
#expand {
	return xx sqlite3_column_double(statement, xx column_index);
}

column_text :: (
	statement: *Sqlite_Statement,
	column_index: int,
	persist := true
) -> (text: string, result: Sqlite_Result) {
	database := sqlite3_db_handle(statement);
	text := "";

	text.data = sqlite3_column_text(statement, xx column_index);
	result := sqlite3_errcode(database);
	if result != .OK then return "", result;

	text.count = sqlite3_column_bytes(statement, xx column_index);
	result = sqlite3_errcode(database);
	if result != .OK then return "", result;

	if persist then text = copy_string(text);
	return text, .OK;
}

column :: (
	statement: *Sqlite_Statement,
	column_index: int,
	$T: Type
) -> (value: T, result: Sqlite_Result) #expand {
	value: T;
	result := column(statement, column_index, *value);
	return value, result;
}

column :: (
	statement: *Sqlite_Statement,
	column_index: int,
	value: *$T
) -> Sqlite_Result
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
		statement: *Sqlite_Statement,
		column_index: int
	) -> (data: [] u8, result: Sqlite_Result) {
		database := sqlite3_db_handle(statement);
		data := sqlite3_column_blob(statement, xx column_index);
		result := sqlite3_errcode(database);
		if data == null then return .[], result;

		count := sqlite3_column_bytes(statement, xx column_index);
		result = sqlite3_errcode(database);
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
		database := sqlite3_db_handle(statement);
		data := sqlite3_column_text(statement, xx column_index);
		result := sqlite3_errcode(database);
		if data == null then return result;

		count := sqlite3_column_bytes(statement, xx column_index);
		result = sqlite3_errcode(database);
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
		result := Sqlite_Result.OK;

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

prepare :: (database: *Sqlite_Database, sql: string) -> (result: Sqlite_Result, statement: *Sqlite_Statement = null, sql_remainder := "") {
	statement: *Sqlite_Statement = ---;
	sql_remainder: *u8 = ---;

	result := sqlite3_prepare_v3(
		database,
		sql.data,
		xx sql.count,
		.PERSISTENT,
		*statement,
		*sql_remainder
	);
	if result != .OK return result;

	return result, statement, to_string(sql_remainder);
}

bind :: (statement: *Sqlite_Statement, params: Any, index: s32 = 1) -> Sqlite_Result {
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

exec :: (
	database: *Sqlite_Database,
	sql: string,
	params := Any.{},
	mapper: (statement: *Sqlite_Statement) -> $T = null,
	cached_statement: **Sqlite_Statement = null
) -> (result: Sqlite_Result, rows: [] T = .[]) {
	statement := ifx cached_statement == null then null else cached_statement.*;
	result := Sqlite_Result.OK;
	remainder := "";

	if statement == null {
		result, statement, remainder = prepare(database, sql);
		if result != .OK return result;
		if cached_statement != null then cached_statement.* = statement;
		assert(remainder == "");
	} else {
		result = sqlite3_clear_bindings(statement);
		if result != .OK return result;
	}

	defer {
		exit_result := Sqlite_Result.OK;
		if cached_statement == null
			exit_result := sqlite3_finalize(statement);
		else
			exit_result := sqlite3_reset(statement);
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

#scope_file

INIT_SQL :: #string SQL
CREATE TABLE IF NOT EXISTS schema_version
	AS SELECT 0 AS version;

SELECT version
FROM schema_version;
SQL

CONNECTION_SQL :: #string SQL
PRAGMA foreign_keys = ON;
SQL

libsqlite3 :: #library,system "libsqlite3";

sqlite3_bind_blob :: (statement: *Sqlite_Statement, index: s32, value: *void, size: s32, lifetime: Sqlite_Lifetime) -> Sqlite_Result #foreign libsqlite3;
sqlite3_bind_blob64 :: (statement: *Sqlite_Statement, index: s32, value: *void, size: u64, lifetime: Sqlite_Lifetime) -> Sqlite_Result #foreign libsqlite3;
sqlite3_bind_double :: (statement: *Sqlite_Statement, index: s32, value: float64) -> Sqlite_Result #foreign libsqlite3;
sqlite3_bind_int :: (statement: *Sqlite_Statement, index: s32, value: s32) -> Sqlite_Result #foreign libsqlite3;
sqlite3_bind_int64 :: (statement: *Sqlite_Statement, index: s32, value: s64) -> Sqlite_Result #foreign libsqlite3;
sqlite3_bind_null :: (statement: *Sqlite_Statement, index: s32) -> Sqlite_Result #foreign libsqlite3;
sqlite3_bind_text :: (statement: *Sqlite_Statement, index: s32, value: *u8, size: s32, lifetime: Sqlite_Lifetime) -> Sqlite_Result #foreign libsqlite3;
sqlite3_bind_text16 :: (statement: *Sqlite_Statement, index: s32, value: *u16, size: s32, lifetime: Sqlite_Lifetime) -> Sqlite_Result #foreign libsqlite3;
sqlite3_bind_text64 :: (statement: *Sqlite_Statement, index: s32, value: *u8, size: u64, lifetime: Sqlite_Lifetime, encoding: Sqlite_Encoding) -> Sqlite_Result #foreign libsqlite3;
sqlite3_bind_value :: (statement: *Sqlite_Statement, index: s32, value: *Sqlite_Value) -> Sqlite_Result #foreign libsqlite3;
sqlite3_bind_parameter_count :: (statement: *Sqlite_Statement) -> s32 #foreign libsqlite3;
sqlite3_bind_parameter_index :: (statement: *Sqlite_Statement, name: *u8) -> s32 #foreign libsqlite3;
sqlite3_bind_parameter_name :: (statement: *Sqlite_Statement, index: s32) -> *u8 #foreign libsqlite3;
sqlite3_bind_pointer :: (statement: *Sqlite_Statement, index: s32, value: *void, type: *u8, lifetime: Sqlite_Lifetime) -> Sqlite_Result #foreign libsqlite3;
sqlite3_bind_zeroblob :: (statement: *Sqlite_Statement, index: s32, size: s32) -> Sqlite_Result #foreign libsqlite3;
sqlite3_bind_zeroblob64 :: (statement: *Sqlite_Statement, index: s32, size: u64) -> Sqlite_Result #foreign libsqlite3;
sqlite3_clear_bindings :: (statement: *Sqlite_Statement) -> Sqlite_Result #foreign libsqlite3;
sqlite3_close :: (database: *Sqlite_Database) -> Sqlite_Result #foreign libsqlite3;
sqlite3_close_v2 :: (database: *Sqlite_Database) -> Sqlite_Result #foreign libsqlite3;
sqlite3_column_blob :: (statement: *Sqlite_Statement, column_index: s32) -> *void #foreign libsqlite3;
sqlite3_column_bytes :: (statement: *Sqlite_Statement, column_index: s32) -> s32 #foreign libsqlite3;
sqlite3_column_bytes16 :: (statement: *Sqlite_Statement, column_index: s32) -> s32 #foreign libsqlite3;
sqlite3_column_count :: (statement: *Sqlite_Statement) -> s32 #foreign libsqlite3;
sqlite3_column_database_name :: (statement: *Sqlite_Statement, column_index: s32) -> *u8 #foreign libsqlite3;
sqlite3_column_database_name16 :: (statement: *Sqlite_Statement, column_index: s32) -> *u16 #foreign libsqlite3;
sqlite3_column_decltype :: (statement: *Sqlite_Statement, column_index: s32) -> *u8 #foreign libsqlite3;
sqlite3_column_decltype16 :: (statement: *Sqlite_Statement, column_index: s32) -> *u16 #foreign libsqlite3;
sqlite3_column_double :: (statement: *Sqlite_Statement, column_index: s32) -> float64 #foreign libsqlite3;
sqlite3_column_int :: (statement: *Sqlite_Statement, column_index: s32) -> s32 #foreign libsqlite3;
sqlite3_column_int64 :: (statement: *Sqlite_Statement, column_index: s32) -> s64 #foreign libsqlite3;
sqlite3_column_name :: (statement: *Sqlite_Statement, column_index: s32) -> *u8 #foreign libsqlite3;
sqlite3_column_name16 :: (statement: *Sqlite_Statement, column_index: s32) -> *u16 #foreign libsqlite3;
sqlite3_column_origin_name :: (statement: *Sqlite_Statement, column_index: s32) -> *u8 #foreign libsqlite3;
sqlite3_column_origin_name16 :: (statement: *Sqlite_Statement, column_index: s32) -> *u16 #foreign libsqlite3;
sqlite3_column_table_name :: (statement: *Sqlite_Statement, column_index: s32) -> *u8 #foreign libsqlite3;
sqlite3_column_table_name16 :: (statement: *Sqlite_Statement, column_index: s32) -> *u16 #foreign libsqlite3;
sqlite3_column_text :: (statement: *Sqlite_Statement, column_index: s32) -> *u8 #foreign libsqlite3;
sqlite3_column_text16 :: (statement: *Sqlite_Statement, column_index: s32) -> *u16 #foreign libsqlite3;
sqlite3_column_type :: (statement: *Sqlite_Statement, column_index: s32) -> Sqlite_Type #foreign libsqlite3;
sqlite3_column_value :: (statement: *Sqlite_Statement, column_index: s32) -> *Sqlite_Value #foreign libsqlite3;
sqlite3_data_count :: (statement: *Sqlite_Statement) -> s32 #foreign libsqlite3;
sqlite3_db_handle :: (statement: *Sqlite_Statement) -> *Sqlite_Database #foreign libsqlite3;
sqlite3_errcode :: (database: *Sqlite_Database) -> Sqlite_Result #foreign libsqlite3;
sqlite3_errmsg :: (database: *Sqlite_Database) -> *u8 #foreign libsqlite3;
sqlite3_errmsg16 :: (database: *Sqlite_Database) -> *u16 #foreign libsqlite3;
sqlite3_error_offset :: (database: *Sqlite_Database) -> s32 #foreign libsqlite3;
sqlite3_errstr :: (result: Sqlite_Result) -> *u8 #foreign libsqlite3;
sqlite3_extended_errcode :: (database: *Sqlite_Database) -> Sqlite_Result #foreign libsqlite3;
sqlite3_extended_result_codes :: (database: *Sqlite_Database, enabled: bool) -> Sqlite_Result #foreign libsqlite3;
sqlite3_finalize :: (statement: *Sqlite_Statement) -> Sqlite_Result #foreign libsqlite3;
sqlite3_open :: (filename: *u8, database: **Sqlite_Database) -> Sqlite_Result #foreign libsqlite3;
sqlite3_open16 :: (filename: *u16, database: **Sqlite_Database) -> Sqlite_Result #foreign libsqlite3;
sqlite3_open_v2 :: (filename: *u8, database: **Sqlite_Database, flags: Sqlite_Open_Flags, vfs_name: *u8) -> Sqlite_Result #foreign libsqlite3;
sqlite3_prepare :: (database: *Sqlite_Database, sql: *u8, size: s32, statement: **Sqlite_Statement, sql_tail: **u8) -> Sqlite_Result #foreign libsqlite3;
sqlite3_prepare_v2 :: (database: *Sqlite_Database, sql: *u8, size: s32, statement: **Sqlite_Statement, sql_tail: **u8) -> Sqlite_Result #foreign libsqlite3;
sqlite3_prepare_v3 :: (database: *Sqlite_Database, sql: *u8, size: s32, flags: Sqlite_Prepare_Flags, statement: **Sqlite_Statement, sql_tail: **u8) -> Sqlite_Result #foreign libsqlite3;
sqlite3_prepare16 :: (database: *Sqlite_Database, sql: *u16, size: s32, statement: **Sqlite_Statement, sql_tail: **u16) -> Sqlite_Result #foreign libsqlite3;
sqlite3_prepare16_v2 :: (database: *Sqlite_Database, sql: *u16, size: s32, statement: **Sqlite_Statement, sql_tail: **u16) -> Sqlite_Result #foreign libsqlite3;
sqlite3_prepare16_v3 :: (database: *Sqlite_Database, sql: *u16, size: s32, flags: Sqlite_Prepare_Flags, statement: **Sqlite_Statement, sql_tail: **u16) -> Sqlite_Result #foreign libsqlite3;
sqlite3_reset :: (statement: *Sqlite_Statement) -> Sqlite_Result #foreign libsqlite3;
sqlite3_step :: (statement: *Sqlite_Statement) -> Sqlite_Result #foreign libsqlite3;

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

bind_primitive :: (statement: *Sqlite_Statement, index: s32, params: Any) -> Sqlite_Result {
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
		encoding: Sqlite_Encoding = ifx value.data && !value.data[value.count] then .UTF8_ZT else .UTF8;
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

#import "Basic";
