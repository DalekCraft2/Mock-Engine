package;

import flixel.util.FlxColor;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.IBitmapDrawable;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;

using StringTools;

// credits, original source https://lassieadventurestudio.wordpress.com/2008/10/07/image-outline/
class ImageOutline
{
	private static var _hex:String = '';
	private static var _alpha:Float = 1;
	private static var _weight:Float = 2;
	private static var _brush:Float = 4;
	private static var m:Matrix;

	/**
	 * Renders a Bitmap display of any DisplayObject with an outline drawn around it.
	 * @note: see param descriptions on "outline" method below.
	 */
	public static function renderImage(src:IBitmapDrawable, weight:Int, color:UInt, alpha:Float = 1, antialias:Bool = false, threshold:Int = 150):Bitmap
	{
		var w:Int = 0;
		var h:Int = 0;

		// extract dimensions from actual object type.
		// (unfortunately, IBitmapDrawable does not include width and height getters.)
		if (Std.isOfType(src, DisplayObject))
		{
			var dsp:DisplayObject = cast src;
			m = dsp.transform.matrix;
			w = Std.int(dsp.width);
			h = Std.int(dsp.height);
		}
		else if (Std.isOfType(src, BitmapData))
		{
			var bmp:BitmapData = cast src;
			w = bmp.width;
			h = bmp.height;
		}

		var render:BitmapData = new BitmapData(w, h, true, FlxColor.TRANSPARENT);
		render.draw(src, m);

		return new Bitmap(ImageOutline.outline(render, weight, color, alpha, antialias, threshold));
	}

	/**
	 * Renders an outline around a BitmapData image.
	 * Outline is rendered based on image's alpha channel.
	 * @param: src = source BitmapData image to outline.
	 * @param: weight = stroke thickness (in pixels) of outline.
	 * @param: color = color of outline.
	 * @param: alpha = opacity of outline (range of 0 to 1).
	 * @param: antialias = smooth edge (true), or jagged edge (false).
	 * @param: threshold = Alpha sensativity to source image (0 - 255). Used when drawing a jagged edge based on an antialiased source image.
	 * @return: BitmapData of rendered outline image.
	 */
	public static function outline(src:BitmapData, weight:Int, color:UInt, alpha:Float = 1, antialias:Bool = false, threshold:Int = 150):BitmapData
	{
		_hex = _toHexString(color);
		_alpha = alpha;
		_weight = weight;
		_brush = (weight * 2) + 1;

		var copy:BitmapData = new BitmapData(Std.int(src.width + _brush), Std.int(src.height + _brush), true, FlxColor.TRANSPARENT);

		for (iy in 0...src.height)
		{
			for (ix in 0...src.width)
			{
				// get current pixel's alpha component.
				var a:Float = src.getPixel32(ix, iy) >> 24 & 0xFF;

				if (antialias)
				{
					// if antialiasing,
					// draw anti-aliased edge.
					_antialias(copy, ix, iy, Std.int(a));
				}
				else if (a > threshold)
				{
					// if aliasing and pixel alpha is above draw threshold,
					// draw aliased edge.
					_alias(copy, ix, iy);
				}
			}
		}

		// merge source image display into the outline shape's canvas.
		copy.copyPixels(src, new Rectangle(0, 0, copy.width, copy.height), new Point(_weight, _weight), null, null, true);
		return copy;
	}

	/**
	 * Renders an antialiased pixel block.
	 */
	private static function _antialias(copy:BitmapData, x:Int, y:Int, a:Int):BitmapData
	{
		if (a > 0)
		{
			for (iy in y...Std.int(y + _brush))
			{
				for (ix in x...Std.int(x + _brush))
				{
					// get current pixel's alpha component.
					var px:Float = (copy.getPixel32(ix, iy) >> 24 & 0xFF);

					// set pixel if it's target adjusted alpha is greater than the current value.
					if (px < (a * _alpha))
						copy.setPixel32(ix, iy, _parseARGB(Std.int(a * _alpha)));
				}
			}
		}
		return copy;
	}

	/**
	 * Renders an aliased pixel block.
	 */
	private static function _alias(copy:BitmapData, x:Int, y:Int):BitmapData
	{
		copy.fillRect(new Rectangle(x, y, _brush, _brush), _parseARGB(Std.int(_alpha * 255)));
		return copy;
	}

	/**
	 * Utility to parse an ARGB value from the current hex value
	 * Hex string is cached on the class so that it does not need to be recalculated for every pixel.
	 */
	private static function _parseARGB(a:Int):UInt
	{
		return Std.parseInt('0x${a.hex()}$_hex');
	}

	/**
	 * Utility to parse a hex string from a hex number.
	 */
	private static function _toHexString(hex:UInt):String
	{
		var r:Int = (hex >> 16);
		var g:Int = (hex >> 8 ^ r << 8);
		var b:Int = (hex ^ (r << 16 | g << 8));

		var red:String = r.hex();
		var green:String = g.hex();
		var blue:String = b.hex();

		red = (red.length < 2) ? '0$red' : red;
		green = (green.length < 2) ? '0$green' : green;
		blue = (blue.length < 2) ? '0$blue' : blue;
		return (red + green + blue).toUpperCase();
	}
}
