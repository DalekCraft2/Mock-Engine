package;

import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Graphics;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.text.AntiAliasType;
import openfl.text.GridFitType;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;

/**
 * stolen from https://github.com/HaxeFlixel/flixel/blob/master/flixel/system/debug/stats/StatsGraph.hx
 */
class HitGraph extends Sprite
{
	private static inline final AXIS_COLOR:FlxColor = FlxColor.WHITE;
	private static inline final AXIS_ALPHA:Float = 0.5;
	private static inline final HISTORY_MAX:Int = 30;

	public var minValue:Float = -(Math.floor((PlayState.rep.replay.sf / 60) * 1000) + 95);
	public var maxValue:Float = Math.floor((PlayState.rep.replay.sf / 60) * 1000) + 95;

	public var showInput:Bool = Options.save.data.inputShow;

	public var graphColor:FlxColor;

	public var history:Array<Array<Dynamic>> = [];

	public var bitmap:Bitmap;

	public var ts:Float;

	private var _axis:Shape;
	private var _width:Int;
	private var _height:Int;
	private var _labelWidth:Int;

	public function new(x:Int, y:Int, width:Int, height:Int)
	{
		super();

		this.x = x;
		this.y = y;
		_width = width;
		_height = height;

		var bm:BitmapData = new BitmapData(width, height);
		bm.draw(this);
		bitmap = new Bitmap(bm);

		_axis = new Shape();
		_axis.x = _labelWidth + 10;

		ts = Math.floor((PlayState.rep.replay.sf / 60) * 1000) / 166;

		var early:TextField = createTextField(10, 10, FlxColor.WHITE, 12);
		var late:TextField = createTextField(10, _height - 20, FlxColor.WHITE, 12);

		early.text = 'Early (${-166 * ts}ms)';
		late.text = 'Late (${166 * ts}ms)';

		addChild(early);
		addChild(late);

		addChild(_axis);

		drawAxes();
	}

	/**
	 * Redraws the axes of the graph.
	 */
	private function drawAxes():Void
	{
		var gfx:Graphics = _axis.graphics;
		gfx.clear();
		gfx.lineStyle(1, AXIS_COLOR, AXIS_ALPHA);

		// y-Axis
		gfx.moveTo(0, 0);
		gfx.lineTo(0, _height);

		// x-Axis
		gfx.moveTo(0, _height);
		gfx.lineTo(_width, _height);

		gfx.moveTo(0, _height / 2);
		gfx.lineTo(_width, _height / 2);
	}

	public static function createTextField(x:Float = 0, y:Float = 0, color:FlxColor = FlxColor.WHITE, size:Int = 12):TextField
	{
		return initTextField(new TextField(), x, y, color, size);
	}

	public static function initTextField<T:TextField>(tf:T, x:Float = 0, y:Float = 0, color:FlxColor = FlxColor.WHITE, size:Int = 12):T
	{
		tf.x = x;
		tf.y = y;
		tf.multiline = false;
		tf.wordWrap = false;
		tf.embedFonts = true;
		tf.selectable = false;
		tf.antiAliasType = AntiAliasType.NORMAL;
		tf.gridFitType = GridFitType.PIXEL;
		tf.defaultTextFormat = new TextFormat(Paths.font('vcr.ttf'), size, color.to24Bit());
		tf.alpha = color.alphaFloat;
		tf.autoSize = TextFieldAutoSize.LEFT;
		return tf;
	}

	private function drawJudgementLine(ms:Float):Void
	{
		var gfx:Graphics = graphics;

		gfx.lineStyle(1, graphColor, 0.3);

		var ts:Float = Math.floor((PlayState.rep.replay.sf / 60) * 1000) / 166;
		var range:Float = Math.max(maxValue - minValue, maxValue * 0.1);

		var value:Float = ((ms * ts) - minValue) / range;

		var pointY:Float = _axis.y + ((-value * _height - 1) + _height);

		var graphX:Float = _axis.x + 1;

		if (ms == 45)
			gfx.moveTo(graphX, _axis.y + pointY);

		graphX = _axis.x + 1;

		gfx.drawRect(graphX, pointY, _width, 1);

		gfx.lineStyle(1, graphColor, 1);
	}

	/**
	 * Redraws the graph based on the values stored in the history.
	 */
	private function drawGraph():Void
	{
		var gfx:Graphics = graphics;
		gfx.clear();
		gfx.lineStyle(1, graphColor, 1);

		gfx.beginFill(FlxColor.GREEN);
		drawJudgementLine(45);
		gfx.endFill();

		gfx.beginFill(FlxColor.RED);
		drawJudgementLine(90);
		gfx.endFill();

		gfx.beginFill(0x8B0000);
		drawJudgementLine(135);
		gfx.endFill();

		gfx.beginFill(0x580000);
		drawJudgementLine(166);
		gfx.endFill();

		gfx.beginFill(FlxColor.GREEN);
		drawJudgementLine(-45);
		gfx.endFill();

		gfx.beginFill(FlxColor.RED);
		drawJudgementLine(-90);
		gfx.endFill();

		gfx.beginFill(0x8B0000);
		drawJudgementLine(-135);
		gfx.endFill();

		gfx.beginFill(0x580000);
		drawJudgementLine(-166);
		gfx.endFill();

		var range:Float = Math.max(maxValue - minValue, maxValue * 0.1);
		var graphX:Float = _axis.x + 1;

		if (showInput)
		{
			for (ana in PlayState.rep.replay.ana.anaArray)
			{
				var value:Float = (ana.key * 25 - minValue) / range;

				if (ana.hit)
					gfx.beginFill(FlxColor.YELLOW);
				else
					gfx.beginFill(0xC2B280);

				if (ana.hitTime < 0)
					continue;

				var pointY:Float = (-value * _height - 1) + _height;
				gfx.drawRect(graphX + fitX(ana.hitTime), pointY, 2, 2);
				gfx.endFill();
			}
		}

		for (i in 0...history.length)
		{
			var value:Float = (history[i][0] - minValue) / range;
			var judge:String = history[i][1];

			switch (judge)
			{
				case 'sick':
					gfx.beginFill(FlxColor.CYAN);
				case 'good':
					gfx.beginFill(FlxColor.GREEN);
				case 'bad':
					gfx.beginFill(FlxColor.RED);
				case 'shit':
					gfx.beginFill(0x8B0000);
				case 'miss':
					gfx.beginFill(0x580000);
				default:
					gfx.beginFill(FlxColor.WHITE);
			}
			var pointY:Float = ((-value * _height - 1) + _height);

			gfx.drawRect(fitX(history[i][2]), pointY, 4, 4);

			gfx.endFill();
		}

		var bm:BitmapData = new BitmapData(_width, _height);
		bm.draw(this);
		bitmap = new Bitmap(bm);
	}

	public function fitX(x:Float):Float
	{
		return ((x / (FlxG.sound.music.length / PlayState.songMultiplier)) * width) * PlayState.songMultiplier;
	}

	public function addToHistory(diff:Float, judge:String, time:Float):Void
	{
		history.push([diff, judge, time]);
	}

	public function update():Void
	{
		drawGraph();
	}

	public function average():Float
	{
		var sum:Float = 0;
		for (value in history)
			sum += value[0];
		return sum / history.length;
	}

	public function destroy():Void
	{
		_axis = FlxDestroyUtil.removeChild(this, _axis);
		history = null;
	}
}
