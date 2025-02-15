package;

import NoteKey.NoteColor;
import flixel.FlxSprite;
import flixel.util.typeLimit.OneOfTwo;
import haxe.io.Path;

// TODO Maybe I should take this "abstract" approach with some other objects what use JSON...
abstract NoteDef(Array<Dynamic>) /*from Array<Dynamic> to Array<Dynamic>*/
{
	public static inline final INDEX_STRUM_TIME:Int = 0;
	public static inline final INDEX_NOTE_DATA:Int = 1;
	public static inline final INDEX_SUSTAIN_LENGTH:Int = 2;
	public static inline final INDEX_NOTE_TYPE:Int = 3;

	public var strumTime(get, set):Float;
	public var noteData(get, set):Int;
	public var sustainLength(get, set):Null<Float>;
	public var noteType(get, set):OneOfTwo<Null<Int>, String>;

	public inline function new(array:Array<Dynamic>)
	{
		this = array;
	}

	private function get_strumTime():Float
	{
		return this[INDEX_STRUM_TIME];
	}

	private function set_strumTime(value:Float):Float
	{
		return this[INDEX_STRUM_TIME] = value;
	}

	private function get_noteData():Int
	{
		return this[INDEX_NOTE_DATA];
	}

	private function set_noteData(value:Int):Int
	{
		return this[INDEX_NOTE_DATA] = value;
	}

	private function get_sustainLength():Null<Float>
	{
		return this[INDEX_SUSTAIN_LENGTH];
	}

	private function set_sustainLength(value:Null<Float>):Null<Float>
	{
		return this[INDEX_SUSTAIN_LENGTH] = value;
	}

	private function get_noteType():OneOfTwo<Null<Int>, String>
	{
		return this[INDEX_NOTE_TYPE];
	}

	private function set_noteType(value:OneOfTwo<Null<Int>, String>):OneOfTwo<Null<Int>, String>
	{
		return this[INDEX_NOTE_TYPE] = value;
	}
}

class Note extends FlxSprite
{
	public static final STRUM_WIDTH:Float = 160 * 0.7;

	public var strumTime:Float = 0;

	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noteWasHit:Bool = false;
	public var prevNote:Note;

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var noteType(default, set):String;

	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';

	public var colorSwap:ColorSwap;
	public var inEditor:Bool = false;
	public var gfNote:Bool = false;

	private var earlyHitMult:Float = 0.5;

	// Script API shit
	public var noteSplashDisabled:Bool = false;
	public var noteSplashTexture:String;
	public var noteSplashHue:Float = 0;
	public var noteSplashSat:Float = 0;
	public var noteSplashBrt:Float = 0;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var hitHealth:Float = 0.023;
	public var missHealth:Float = 0.0475;
	public var rating:String = 'unknown';
	public var ratingMod:Float = 0; // 9 = unknown, 0.25 = shit, 0.5 = bad, 0.75 = good, 1 = sick
	public var ratingDisabled:Bool = false;

	public var texture(default, set):String;

	public var noAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var distance:Float = 2000; // plan on doing scroll directions soon -bb

	public var hitsoundDisabled:Bool = false;

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?isSustainNote:Bool = false, ?inEditor:Bool = false)
	{
		super();

		this.prevNote = prevNote == null ? this : prevNote;
		this.isSustainNote = isSustainNote;
		this.inEditor = inEditor;

		x += (Options.save.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;
		this.strumTime = strumTime;
		if (!inEditor)
			this.strumTime += Options.save.data.noteOffset;

		this.noteData = Std.int(Math.abs(noteData));

		if (this.noteData > -1)
		{
			texture = '';
			colorSwap = new ColorSwap();
			shader = colorSwap.shader;

			x += STRUM_WIDTH * (this.noteData % 4);
			if (!isSustainNote)
			{ // Doing this 'if' check to fix the warnings on Senpai songs
				var animToPlay:String = NoteColor.createByIndex(this.noteData % 4).getName();
				animation.play('${animToPlay}Scroll');
			}
		}

		if (isSustainNote && prevNote != null)
		{
			alpha = 0.6;
			multAlpha = 0.6;
			hitsoundDisabled = true;
			if (Options.save.data.downScroll)
				flipY = true;

			offsetX += width / 2;
			copyAngle = false;

			var animToPlay:String = NoteColor.createByIndex(this.noteData % 4).getName();
			animation.play('${animToPlay}holdend');

			updateHitbox();

			offsetX -= width / 2;

			if (PlayState.isPixelStage)
				offsetX += 30;

			if (prevNote.isSustainNote)
			{
				var animToPlay:String = NoteColor.createByIndex(prevNote.noteData % 4).getName();
				prevNote.animation.play('${animToPlay}hold');

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
				if (PlayState.instance != null)
				{
					prevNote.scale.y *= PlayState.instance.songSpeed;
				}

				if (PlayState.isPixelStage)
				{
					prevNote.scale.y *= 1.19;
					prevNote.scale.y *= (6 / height); // Auto adjust note size
				}
				prevNote.updateHitbox();
			}

			if (PlayState.isPixelStage)
			{
				scale.y *= PlayState.PIXEL_ZOOM;
				updateHitbox();
			}
		}
		else if (!isSustainNote)
		{
			earlyHitMult = 1;
		}
		x += offsetX;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (mustPress)
		{
			// ok river
			if (strumTime > Conductor.songPosition - Conductor.safeZoneOffset
				&& strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult))
				canBeHit = true;
			else
				canBeHit = false;

			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			canBeHit = false;

			if (strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult))
			{
				if ((isSustainNote && prevNote.wasGoodHit) || strumTime <= Conductor.songPosition)
					wasGoodHit = true;
			}
		}

		if (tooLate && !inEditor)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}

	private var lastNoteOffsetXForPixelAutoAdjusting:Float = 0;
	private var lastNoteScaleToo:Float = 1;

	public var originalHeightForCalcs:Float = 6;

	private function reloadNote(?prefix:String = '', ?texture:String = '', ?suffix:String = ''):Void
	{
		var skin:String = texture;
		if (texture.length < 1)
		{
			skin = PlayState.song.arrowSkin;
			if (skin == null || skin.length < 1)
			{
				skin = 'NOTE_assets';
			}
		}

		var animName:Null<String> = null;
		if (animation.curAnim != null)
		{
			animName = animation.curAnim.name;
		}

		var arraySkin:Array<String> = skin.split('/');
		arraySkin[arraySkin.length - 1] = prefix + arraySkin[arraySkin.length - 1] + suffix;

		var lastScaleY:Float = scale.y;
		var blahblah:String = arraySkin.join('/');
		if (PlayState.isPixelStage)
		{
			if (isSustainNote)
			{
				loadGraphic(Paths.getGraphic(Path.join(['weeb/pixelUI', '${blahblah}ENDS']), 'week6'));
				width = width / 4;
				height = height / 2;
				originalHeightForCalcs = height;
				loadGraphic(Paths.getGraphic(Path.join(['weeb/pixelUI', '${blahblah}ENDS']), 'week6'), true, Math.floor(width), Math.floor(height));
			}
			else
			{
				loadGraphic(Paths.getGraphic(Path.join(['weeb/pixelUI', blahblah]), 'week6'));
				width = width / 4;
				height = height / 5;
				loadGraphic(Paths.getGraphic(Path.join(['weeb/pixelUI', blahblah]), 'week6'), true, Math.floor(width), Math.floor(height));
			}
			setGraphicSize(Std.int(width * PlayState.PIXEL_ZOOM));
			loadPixelNoteAnims();
			antialiasing = false;

			if (isSustainNote)
			{
				offsetX += lastNoteOffsetXForPixelAutoAdjusting;
				lastNoteOffsetXForPixelAutoAdjusting = (width - 7) * (PlayState.PIXEL_ZOOM / 2);
				offsetX -= lastNoteOffsetXForPixelAutoAdjusting;

				/*
					if (animName != null && !animName.endsWith('end'))
					{
						lastScaleY /= lastNoteScaleToo;
						lastNoteScaleToo = (6 / height);
						lastScaleY *= lastNoteScaleToo;
					}
				 */
			}
		}
		else
		{
			frames = Paths.getSparrowAtlas(blahblah);
			loadNoteAnims();
			antialiasing = Options.save.data.globalAntialiasing;
		}
		if (isSustainNote)
		{
			scale.y = lastScaleY;
		}
		updateHitbox();

		if (animName != null)
			animation.play(animName, true);
	}

	private function loadNoteAnims():Void
	{
		for (color in NoteColor.createAll())
		{
			animation.addByPrefix('${color}Scroll', '${color} alone'); // Normal notes

			if (isSustainNote)
			{
				animation.addByPrefix('${color}hold', '${color} hold'); // Holds
				animation.addByPrefix('${color}holdend', '${color} tail'); // Tails
			}
		}

		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();
	}

	private function loadPixelNoteAnims():Void
	{
		for (color in NoteColor.createAll())
		{
			if (isSustainNote)
			{
				animation.add('${color.getName()}holdend', [color.getIndex() + 4]); // Tails
				animation.add('${color.getName()}hold', [color.getIndex()]); // Holds
			}
			else
			{
				animation.add('${color.getName()}Scroll', [color.getIndex() + 4]); // Normal notes
			}
		}
	}

	private function set_texture(value:String):String
	{
		if (texture != value)
		{
			reloadNote('', value);
		}
		texture = value;
		return value;
	}

	private function set_noteType(value:String):String
	{
		noteSplashTexture = PlayState.song.splashSkin;
		colorSwap.hue = Options.save.data.arrowHSV[noteData % 4][0] / 360;
		colorSwap.saturation = Options.save.data.arrowHSV[noteData % 4][1] / 100;
		colorSwap.brightness = Options.save.data.arrowHSV[noteData % 4][2] / 100;

		if (noteData > -1 && noteType != value)
		{
			switch (value)
			{
				case 'Hurt Note':
					ignoreNote = mustPress;
					reloadNote('HURT');
					noteSplashTexture = 'HURTnoteSplashes';
					colorSwap.hue = 0;
					colorSwap.saturation = 0;
					colorSwap.brightness = 0;
					if (isSustainNote)
					{
						missHealth = 0.1;
					}
					else
					{
						missHealth = 0.3;
					}
					hitCausesMiss = true;
				case 'No Animation':
					noAnimation = true;
				case 'GF Sing':
					gfNote = true;
			}
			noteType = value;
		}
		noteSplashHue = colorSwap.hue;
		noteSplashSat = colorSwap.saturation;
		noteSplashBrt = colorSwap.brightness;
		return value;
	}
}
