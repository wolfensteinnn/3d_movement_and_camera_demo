@tool
extends EditorScript

func _run():
	var demo = get_scene().get_node("Sketchfab_Scene/Sketchfab_model/2461dbe20d314730bf2e726dc8864774_fbx/RootNode/Demo")
	add_collisions_recursive(demo)

func add_collisions_recursive(node: Node):
	if node is MeshInstance3D:
		node.create_trimesh_collision()
	for child in node.get_children():
		add_collisions_recursive(child)
