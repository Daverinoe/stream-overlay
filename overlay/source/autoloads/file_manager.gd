extends Node

func list_files_in_folder(path : String) -> Array:
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()
	
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with(".") and file.ends_with(".import"):
			var file_name = file.replace('.import', '')
			files.append(file_name)
	
	dir.list_dir_end()
	return files
