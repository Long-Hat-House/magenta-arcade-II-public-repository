# res://addons/google_sheet_importer/sheet_data_inspector.gd
@tool
extends EditorInspectorPlugin

func _can_handle(object):
	return object is SheetData

func _parse_begin(object: Object) -> void:
	if object is SheetData:

		# Create the control that holds the button
		var control = VBoxContainer.new()

		# Create the Reimport Button
		var reimport_button = Button.new()
		reimport_button.text = "🔄 Fetch & Reimport Sheet Data"
		reimport_button.tooltip_text = "Downloads the CSV data from Google Sheets and saves this resource."
		reimport_button.custom_minimum_size = Vector2(0, 30)

		# Connect the button to the 'reimport' method of the SheetData object
		# We use call_deferred to prevent blocking the editor thread
		reimport_button.pressed.connect(object.reimport)

		control.add_child(reimport_button)

		# A label to show where the data is stored
		var label = Label.new()
		label.text = "Data Rows: %d" % object.rows.size()
		control.add_child(label)

		add_custom_control(control)
