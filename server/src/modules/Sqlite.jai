init :: (lib_path: string, db_path: string, sql: string) {
	file_delete(db_path);

	result := run_command(lib_path, db_path);
}
