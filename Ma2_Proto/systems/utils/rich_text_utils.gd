enum RichTextColor{
		Black,
		Gray,
		White,
		Blue,
		Red,
		Green,
		Yellow,
		Orange,
		Cyan,
		Pink,
		Magenta,
		Purple
}

static func get_rich_text_color(c:RichTextColor)->String:
	match c:
		RichTextColor.Black:
			return "black";
		RichTextColor.Gray:
			return "gray";
		RichTextColor.White:
			return "white";
		RichTextColor.Blue:
			return "blue";
		RichTextColor.Red:
			return "red";
		RichTextColor.Green:
			return "green";
		RichTextColor.Yellow:
			return "yellow";
		RichTextColor.Orange:
			return "orange";
		RichTextColor.Cyan:
			return "cyan";
		RichTextColor.Pink:
			return "pink";
		RichTextColor.Magenta:
			return "magenta";
		RichTextColor.Purple:
			return "purple";
	return "gray";
	
static func in_color(str:String, c:RichTextColor):
	return "[color=%s]%s[/color]" % [get_rich_text_color(c), str];
