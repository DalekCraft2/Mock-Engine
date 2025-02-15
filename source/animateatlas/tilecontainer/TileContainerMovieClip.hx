package animateatlas.tilecontainer;

import animateatlas.HelperEnums.LoopMode;
import animateatlas.HelperEnums.SymbolType;
import openfl.display.TileContainer;

@:access(animateatlas.tilecontainer.TileContainerSymbol)
class TileContainerMovieClip extends TileContainer
{
	public var frameRate(get, set):Float;
	public var currentLabel(get, set):String;
	public var currentFrame(get, set):Int;
	public var type(get, set):String;
	public var loopMode(get, set):String;
	public var symbolName(get, never):String;
	public var numLayers(get, never):Int;
	public var numFrames(get, never):Int;
	public var layers(get, never):Array<TileContainer>; // ! Dangerous AF.

	private var symbol:TileContainerSymbol;
	private var _frameRate:Null<Float>;
	private var frameElapsed:Float = 0;

	public function new(symbol:TileContainerSymbol)
	{
		super();

		this.symbol = symbol;
		addTile(this.symbol);
	}

	public function update(dt:Int):Void
	{
		var frameDuration:Float = 1000 / frameRate;
		frameElapsed += dt;

		while (frameElapsed > frameDuration)
		{
			frameElapsed -= frameDuration;
			symbol.nextFrame();
		}
		while (frameElapsed < -frameDuration)
		{
			frameElapsed += frameDuration;
			symbol.prevFrame();
		}
	}

	public function getFrameLabels():Array<String>
	{
		return symbol.getFrameLabels();
	}

	public function getFrame(label:String):Int
	{
		return symbol.getFrame(label);
	}

	public function getFramesofAnim(label:String):Int
	{
		var uncalculatedArray:Array<Int> = [];
		var uncalculatedFrames:Int = 0;

		for (frameLabel in getFrameLabels())
		{
			uncalculatedArray.push(getFrame(frameLabel));
		}

		uncalculatedFrames = uncalculatedArray[0] + uncalculatedArray.length;

		return uncalculatedFrames;
	}

	// # region Property setter and getter

	private function get_currentLabel():String
	{
		return symbol.currentLabel;
	}

	private function set_currentLabel(value:String):String
	{
		symbol.currentFrame = symbol.getFrame(value);
		return currentLabel;
	}

	private function get_currentFrame():Int
	{
		return symbol.currentFrame;
	}

	private function set_currentFrame(value:Int):Int
	{
		symbol.currentFrame = value;
		return currentFrame;
	}

	private function get_type():SymbolType
	{
		return symbol.type;
	}

	private function set_type(value:SymbolType):SymbolType
	{
		symbol.type = value;
		return type;
	}

	private function get_loopMode():LoopMode
	{
		return symbol.loopMode;
	}

	private function set_loopMode(value:LoopMode):LoopMode
	{
		symbol.loopMode = value;
		return loopMode;
	}

	private function get_symbolName():String
	{
		return symbol.symbolName;
	}

	private function get_numLayers():Int
	{
		return symbol.numLayers;
	}

	private function get_numFrames():Int
	{
		return symbol.numFrames;
	}

	private function get_layers():Array<TileContainer>
	{
		return symbol._layers;
	}

	private function get_frameRate():Float
	{
		return _frameRate == null ? symbol._library.frameRate : _frameRate;
	}

	private function set_frameRate(value:Float):Float
	{
		_frameRate = value;
		return frameRate;
	}

	// # end region
}
