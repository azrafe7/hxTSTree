package ;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.filters.GlowFilter;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFieldType;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

/**
 * ...
 * @author azrafe7
 */
class TextBox extends Sprite
{
	static var TEXT_COLOR:Int = 0xFFFFFFFF;
	static var TEXT_INPUT_BG:Int = 0xFF605050;
	static var TEXT_INPUT_WIDTH:Int = 140;
	static var TEXT_INPUT_BORDER:Int = 0xFF202020;
	static var TEXT_FONT:String = "_typewriter";
	static var TEXT_SIZE:Float = 12;
	static var TEXT_OUTLINE:GlowFilter = new GlowFilter(0xFF000000, 1, 2, 2, 6);
	
	var maxResults:Int;
	var onChange:Dynamic->Void;
	var labelTextField:TextField;
	var inputTextField:TextField;
	var resultsTextField:TextField;
	

	public function new(text:String, x:Float, y:Float, maxResults:Int = 15, onChange:Dynamic->Void) 
	{
		super();
		
		this.maxResults = maxResults;
		labelTextField = getTextField(text, x, y - TEXT_SIZE - 8, TEXT_SIZE);
		inputTextField = getTextField("", x, y, TEXT_SIZE, true);
		resultsTextField = getTextField("", x, y + TEXT_SIZE + 8, TEXT_SIZE, false);
		
		addChild(labelTextField);
		addChild(inputTextField);
		addChild(resultsTextField);
		
		this.onChange = onChange;
		this.addEventListener(Event.CHANGE, this.onChange);
	}
	
	public var text(get, set):String;
	private function get_text():String { return inputTextField.text;	}
	private function set_text(value:String):String { return inputTextField.text = value; }
	
	public var results(default, set):Array<String>;
	private function set_results(values:Array<String>):Array<String>
	{
		resultsTextField.text = maxResults > 0 ? '[${values.length} results]\n' : "";
		for (i in 0...values.length) {
			if (i > maxResults && maxResults > 0) {
				resultsTextField.appendText("...");
				break;
			} else {
				resultsTextField.appendText(values[i] + "\n");
			}
		}
		
		return values;
	}
	
	static public function getTextField(text:String = "", x:Float, y:Float, ?size:Float, inputType:Bool = false):TextField
	{
		var tf:TextField = new TextField();
		var fmt:TextFormat = new TextFormat(TEXT_FONT, null, TEXT_COLOR);
		fmt.align = TextFormatAlign.LEFT;
		fmt.size = size == null ? TEXT_SIZE : size;
		if (inputType) {
			tf.type = TextFieldType.INPUT;
			tf.background = true;
			tf.backgroundColor = TEXT_INPUT_BG;
			tf.border = true;
			tf.borderColor = TEXT_INPUT_BORDER;
			tf.width = TEXT_INPUT_WIDTH;
			tf.multiline = false;
			tf.height = tf.textHeight + 4;
		} else {
			tf.autoSize = TextFieldAutoSize.LEFT;
			tf.multiline = true;
			tf.filters = [TEXT_OUTLINE];
		}
		tf.defaultTextFormat = fmt;
		tf.selectable = inputType;
		tf.x = x;
		tf.y = y;
		tf.text = text;
		return tf;
	}

}