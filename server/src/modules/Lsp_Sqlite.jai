Statement_Id :: enum {
	GET_LINKED_RANGES;
	COUNT;
}

Connection :: struct {
	connection: *Sqlite.Connection;
	statement_cache: [Statement_Id.COUNT] *Sqlite.Statement;
}

Link_Type :: enum {
	DEFINITION;
}

Project :: struct {
	main_document_uri: string;
	last_open_epoch: int;
}

init :: (filename: string) -> Connection {
	result, sqlite_connection := Sqlite.open(filename);
	assert(result == .OK);

	connection := Connection.{};
	connection.connection = sqlite_connection;

	result := Sqlite.exec(
		sqlite_connection,
		#string SQL
			PRAGMA foreign_keys = ON;

			CREATE TABLE IF NOT EXISTS schema_version AS
			SELECT 0 AS version;
		SQL
	);
	assert(result == .OK);

	apply_migrations(connection);

	return connection;
}

deinit :: (connection: *Connection) {
	if !connection.connection return;

	for * connection.statement_cache {
		if it.* {
			result := Sqlite.finalize(it.*);
			assert(result == .OK);
			it.* = null;
		}
	}

	result := Sqlite.close(connection.connection);
	assert(result == .OK);
	connection.connection = null;
}

get_linked_ranges :: (
	connection: *Connection,
	project_id: int,
	document_uri: string,
	source_line: int,
	source_char: int,
	link_type: Link_Type
) -> [] LSP_Location {
	result, rows := Sqlite.exec(
		connection.connection,
		#string SQL
			WITH source_ranges AS (
				SELECT ranges.range_id
				FROM ranges
				JOIN documents
					ON documents.document_id = ranges.document_id
				WHERE documents.document_uri = @document_uri
					AND (ranges.start_line < @source_line
						OR (ranges.start_line = @source_line
							AND ranges.start_char <= @source_char))
					AND (ranges.end_line > @source_line
						OR (ranges.end_line = @source_line
							AND ranges.end_char >= @source_char))
				ORDER BY
					ranges.start_line DESC,
					ranges.start_char DESC,
					ranges.end_line ASC,
					ranges.end_char ASC
			)
			SELECT
				documents.document_uri,
				target_ranges.start_line,
				target_ranges.start_char,
				target_ranges.end_line,
				target_ranges.end_char
			FROM source_ranges
			JOIN range_links
				ON range_links.project_id = @project_id
				AND range_links.link_type = @link_type
				AND range_links.source_range_id = source_ranges.range_id
			JOIN ranges AS target_ranges
				ON target_ranges.range_id = range_links.target_range_id
			JOIN documents
				ON documents.document_id = target_ranges.document_id
		SQL,
		struct {
			project_id: int;
			document_uri: string;
			source_line: int;
			source_char: int;
			link_type: Link_Type;
		}.{
			project_id,
			document_uri,
			source_line,
			source_char,
			link_type
		},
		(statement: *Sqlite.Statement) -> LSP_Location {
			return .{
				uri = Sqlite.column(statement, 0, string),
				range = .{
					start = .{
						line = Sqlite.column(statement, 1, u32),
						character = Sqlite.column(statement, 2, u32),
					},
					end = .{
						line = Sqlite.column(statement, 3, u32),
						character = Sqlite.column(statement, 4, u32),
					}
				}
			};
		},
		*connection.statement_cache[Statement_Id.GET_LINKED_RANGES]
	);
	assert(result == .OK);
	return rows;
}

// get_projects
// invalidate_projects
// get_documents
// invalidate_documents
// invalidate_region
// insert_linked_range

#scope_file

SCHEMA_MIGRATIONS :: string.[
// Base Schema
#string SQL
CREATE TABLE documents (
	document_id INTEGER PRIMARY KEY,
	document_uri TEXT UNIQUE NOT NULL,
	last_edit_epoch INTEGER NOT NULL
) STRICT;

CREATE TABLE projects (
	project_id INTEGER PRIMARY KEY,
	main_document_id INTEGER NOT NULL
		REFERENCES documents (document_id) ON DELETE CASCADE,
	last_open_epoch INTEGER NOT NULL
) STRICT;

CREATE TABLE ranges (
	range_id INTEGER PRIMARY KEY,
	document_id INTEGER NOT NULL
		REFERENCES documents (document_id) ON DELETE CASCADE,
	start_line INTEGER NOT NULL,
	start_char INTEGER NOT NULL,
	end_line INTEGER NOT NULL,
	end_char INTEGER NOT NULL,
	UNIQUE (document_id, start_line, start_char, end_line, end_char)
) STRICT;

CREATE TABLE range_links (
	project_id INTEGER NOT NULL
		REFERENCES projects (project_id) ON DELETE CASCADE,
	link_type INTEGER NOT NULL,
	source_range_id INTEGER NOT NULL
		REFERENCES ranges (range_id) ON DELETE CASCADE,
	target_range_id INTEGER NOT NULL
		REFERENCES ranges (range_id) ON DELETE CASCADE,
	PRIMARY KEY (project_id, link_type, source_range_id, target_range_id)
) STRICT WITHOUT ROWID;
SQL
];

apply_migrations :: (connection: *Connection) {
	result, rows = Sqlite.exec(
		connection.database,
		#string SQL
			SELECT version
			FROM schema_version
		SQL,
		mapper = (statement: *Sqlite.Statement) -> int {
			return Sqlite.column(statement, 0, int);
		}
	);
	assert(result == .OK);

	version := ifx rows.count then rows[0] else 0;
	Basic.array_free(rows);

	for version .. SCHEMA_MIGRATIONS.count - 1 {
		result = Sqlite.exec(
			connection.database,
			SCHEMA_MIGRATIONS[it]
		);
		assert(result == .OK);
	}

	result = Sqlite.exec(
		connection.database,
		#string SQL
			UPDATE schema_version
			SET version = @version
		SQL,
		params = struct { version: int; }.{ SCHEMA_MIGRATIONS.count }
	);
	assert(result == .OK);
}

Basic :: #import "Basic";
assert :: Basic.assert;

#import "Lsp_Types";
Sqlite :: #import "Sqlite";
