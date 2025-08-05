@tool 
extends EditorScript

##COLORS
var primary_color := Color.MEDIUM_PURPLE
var secondary_color := Color.DARK_SLATE_GRAY
var accent_color := Color.GOLD
var background_color := Color.MEDIUM_PURPLE

var theme:Theme = preload("default_theme.theme")
var dir = ""

var tags =[	"h1", "h2", "h3", "p", ""]

func round_all_corners(i):
	var stylebox_dir = dir.path_join("Stylebox/")
	var files = DirAccess.get_files_at(stylebox_dir)
	for subdir in DirAccess.get_directories_at(stylebox_dir):		
		for file in DirAccess.get_files_at(stylebox_dir.path_join(subdir)):
			files.push_back(subdir.path_join(file))
	for file in files:
		var stylebox:StyleBox = load(stylebox_dir.path_join(file))
		if stylebox is StyleBoxFlat:
			stylebox.set_corner_radius_all(i)

func change_button_color(name:String, new_color:Color):
	var stylebox_dir = dir.path_join("Stylebox/" + name + "/")
	for file in DirAccess.get_files_at(stylebox_dir):
		var stylebox:StyleBox = load(stylebox_dir.path_join(file))
		if stylebox is StyleBoxFlat:
			stylebox.bg_color = new_color
			
	
func _run():	
	round_all_corners(20)
	change_button_color("BigButton", Color.GOLDENROD)
	pass
	#for type in theme.get_icon_type_list():
		#for item in theme.get_icon_list(type):			
			#var the_item = theme.get_icon(item, type)						
			#var path = dir.path_join("Icons").path_join(type+"_"+item+".png")			
			#if not FileAccess.file_exists(path):
				#print(path)
				#the_item.get_image().save_png(path)										
			#theme.set_icon(item,type,load(path))
	#for type in theme.get_stylebox_type_list():
		#for item in theme.get_stylebox_list(type):			
			#var the_item:StyleBox = theme.get_stylebox(item, type)
			#var path = dir.path_join("Stylebox").path_join(type+"_"+item+".tres")			
			#if not ResourceLoader.exists(path):
				#ResourceSaver.save(the_item, path)			
			#else:
				#the_item.take_over_path(path)
			#theme.set_stylebox(item,type,the_item)
	#for type in theme.get_font_type_list():
		#for item in theme.get_font_list(type):			
			#var the_item = theme.get_font(item, type)
			#var path = dir.path_join("Fonts").path_join(type+"_"+item+".tres")			
			#if not ResourceLoader.exists(path):
				#ResourceSaver.save(the_item, path)			
			#else:
				#the_item.take_over_path(path)
			#theme.set_font(item,type,the_item)
			#print('saving: ', type,":",item)
	#for type in theme.get_color_type_list():
		#for item in theme.get_color_list(type):
			#print(type,":",item)
			#var the_item = theme.get_color(item, type)
			#ResourceSaver.save(the_item, dir.path_join("Stylebox").path_join(type+"_"+item))
			#print('saving: ', type,":",item)
