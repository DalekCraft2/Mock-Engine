package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.system.FlxSound;
import flixel.util.FlxTimer;

using StringTools;

/**
 * Loosely based on FlxTypeText lolol
 */
class Alphabet extends FlxSpriteGroup
{
	private static final LETTERS:String = 'abcdefghijklmnopqrstuvwxyz';
	private static final NUMBERS:String = '1234567890';
	private static final SYMBOLS:String = "!#$%&'()*+,./:;<=>?@[\\]^_|×-“”←↑→↓♥";

	public var delay:Float = 0.05;
	public var paused:Bool = false;

	// for menu shit
	public var forceX:Float = Math.NEGATIVE_INFINITY;
	public var targetY:Float = 0;
	public var yMult:Float = 120;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;
	public var isMenuItem:Bool = false;
	public var textSize:Float = 1.0;

	public var text:String = '';

	private var _finalText:String = '';
	private var yMulti:Float = 1;

	// custom shit
	// amp, backslash, question mark, apostrophy, comma, angry face, period
	private var lastSprite:AlphaCharacter;
	private var xPosResetted:Bool = false;

	private var splitWords:Array<String> = [];

	public var isBold:Bool = false;
	public var lettersArray:Array<AlphaCharacter> = [];

	public var finishedText:Bool = false;
	public var typed:Bool = false;

	public var typingSpeed:Float = 0.05;

	public function new(x:Float, y:Float, text:String = '', ?bold:Bool = false, typed:Bool = false, ?typingSpeed:Float = 0.05, ?textSize:Float = 1)
	{
		super(x, y);

		forceX = Math.NEGATIVE_INFINITY;
		this.textSize = textSize;

		_finalText = text;
		this.text = text;
		this.typed = typed;
		isBold = bold;

		if (text != '')
		{
			if (typed)
			{
				startTypedText(typingSpeed);
			}
			else
			{
				addText();
			}
		}
		else
		{
			finishedText = true;
		}
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (isMenuItem)
		{
			var scaledY:Float = FlxMath.remapToRange(targetY, 0, 1, 0, 1.3);

			var lerpVal:Float = FlxMath.bound(elapsed * 9.6, 0, 1);
			y = FlxMath.lerp(y, (scaledY * yMult) + (FlxG.height * 0.48) + yAdd, lerpVal);
			if (forceX != Math.NEGATIVE_INFINITY)
			{
				x = forceX;
			}
			else
			{
				x = FlxMath.lerp(x, (targetY * 20) + 90 + xAdd, lerpVal);
			}
		}
	}

	public function changeText(newText:String, newTypingSpeed:Float = -1):Void
	{
		while (lettersArray.length > 0)
		{
			var letter:AlphaCharacter = lettersArray[0];
			letter.destroy();
			remove(letter);
			lettersArray.remove(letter);
		}

		lettersArray = [];
		splitWords = [];
		loopNum = 0;
		xPos = 0;
		curRow = 0;
		consecutiveSpaces = 0;
		xPosResetted = false;
		finishedText = false;
		lastSprite = null;

		var lastX:Float = x;
		x = 0;
		_finalText = newText;
		text = newText;
		if (newTypingSpeed != -1)
		{
			typingSpeed = newTypingSpeed;
		}

		if (text != '')
		{
			if (typed)
			{
				startTypedText(typingSpeed);
			}
			else
			{
				addText();
			}
		}
		else
		{
			finishedText = true;
		}
		x = lastX;
	}

	public function addText():Void
	{
		doSplitWords();

		var charXPos:Float = 0;
		for (character in splitWords)
		{
			var spaceChar:Bool = (character == ' ' || (isBold && character == '_'));
			if (spaceChar)
			{
				consecutiveSpaces++;
			}

			var isNumber:Bool = NUMBERS.contains(character);
			var isSymbol:Bool = SYMBOLS.contains(character);
			var isAlphabet:Bool = LETTERS.contains(character.toLowerCase());
			if ((isAlphabet || isSymbol || isNumber) && (!isBold || !spaceChar))
			{
				if (lastSprite != null)
				{
					charXPos = lastSprite.x + lastSprite.width;
				}

				if (consecutiveSpaces > 0)
				{
					charXPos += 40 * consecutiveSpaces * textSize;
				}
				consecutiveSpaces = 0;

				var letter:AlphaCharacter = new AlphaCharacter(charXPos, 0, textSize, isBold);

				if (isBold)
				{
					if (isNumber)
					{
						letter.createBoldNumber(character);
					}
					else if (isSymbol)
					{
						letter.createBoldSymbol(character);
					}
					else
					{
						letter.createBoldLetter(character);
					}
				}
				else
				{
					if (isNumber)
					{
						letter.createNumber(character);
					}
					else if (isSymbol)
					{
						letter.createSymbol(character);
					}
					else
					{
						letter.createLetter(character);
					}
				}

				add(letter);
				lettersArray.push(letter);

				lastSprite = letter;
			}
		}
	}

	private function doSplitWords():Void
	{
		splitWords = _finalText.split('');
	}

	private var loopNum:Int = 0;
	private var xPos:Float = 0;

	public var curRow:Int = 0;

	private var dialogueSound:FlxSound;

	private static var soundDialog:FlxSoundAsset;

	private var consecutiveSpaces:Int = 0;

	// TODO Make this not static
	public static function setDialogueSound(name:String = ''):Void
	{
		if (name.trim() == '')
			name = 'dialogue';
		soundDialog = Paths.getSound(name);
		if (soundDialog == null)
			soundDialog = Paths.getSound('dialogue');
	}

	private var typeTimer:FlxTimer;

	public function startTypedText(speed:Float):Void
	{
		_finalText = text;
		doSplitWords();

		if (soundDialog == null)
		{
			Alphabet.setDialogueSound();
		}

		if (speed <= 0)
		{
			while (!finishedText)
			{
				timerCheck();
			}
			if (dialogueSound != null)
				dialogueSound.stop();
			dialogueSound = FlxG.sound.play(soundDialog);
		}
		else
		{
			typeTimer = new FlxTimer().start(0.1, (tmr:FlxTimer) ->
			{
				typeTimer = new FlxTimer().start(speed, (tmr:FlxTimer) ->
				{
					timerCheck(tmr);
				}, 0);
			});
		}
	}

	private static final LONG_TEXT_ADD:Float = -24; // text is over 2 rows long, make it go up a bit

	public function timerCheck(?tmr:FlxTimer):Void
	{
		var autoBreak:Bool = false;
		if ((loopNum <= splitWords.length - 2 && splitWords[loopNum] == '\\' && splitWords[loopNum + 1] == 'n')
			|| ((autoBreak = true) && xPos >= FlxG.width * 0.65 && splitWords[loopNum] == ' '))
		{
			if (autoBreak)
			{
				if (tmr != null)
					tmr.loops -= 1;
				loopNum += 1;
			}
			else
			{
				if (tmr != null)
					tmr.loops -= 2;
				loopNum += 2;
			}
			yMulti += 1;
			xPosResetted = true;
			xPos = 0;
			curRow += 1;
			if (curRow == 2)
				y += LONG_TEXT_ADD;
		}

		if (loopNum <= splitWords.length && splitWords[loopNum] != null)
		{
			var spaceChar:Bool = (splitWords[loopNum] == ' ' || (isBold && splitWords[loopNum] == '_'));
			if (spaceChar)
			{
				consecutiveSpaces++;
			}

			var isNumber:Bool = NUMBERS.contains(splitWords[loopNum]);
			var isSymbol:Bool = SYMBOLS.contains(splitWords[loopNum]);
			var isAlphabet:Bool = LETTERS.contains(splitWords[loopNum].toLowerCase());

			if ((isAlphabet || isSymbol || isNumber) && (!isBold || !spaceChar))
			{
				if (lastSprite != null && !xPosResetted)
				{
					lastSprite.updateHitbox();
					xPos += lastSprite.width + 3;
				}
				else
				{
					xPosResetted = false;
				}

				if (consecutiveSpaces > 0)
				{
					xPos += 20 * consecutiveSpaces * textSize;
				}
				consecutiveSpaces = 0;

				var letter:AlphaCharacter = new AlphaCharacter(xPos, 55 * yMulti, textSize, isBold);
				letter.row = curRow;
				if (isBold)
				{
					if (isNumber)
					{
						letter.createBoldNumber(splitWords[loopNum]);
					}
					else if (isSymbol)
					{
						letter.createBoldSymbol(splitWords[loopNum]);
					}
					else
					{
						letter.createBoldLetter(splitWords[loopNum]);
					}
				}
				else
				{
					if (isNumber)
					{
						letter.createNumber(splitWords[loopNum]);
					}
					else if (isSymbol)
					{
						letter.createSymbol(splitWords[loopNum]);
					}
					else
					{
						letter.createLetter(splitWords[loopNum]);
					}
				}
				letter.x += 90;

				if (tmr != null)
				{
					if (dialogueSound != null)
						dialogueSound.stop();
					dialogueSound = FlxG.sound.play(soundDialog);
				}

				add(letter);

				lastSprite = letter;
			}
		}

		loopNum++;
		if (loopNum >= splitWords.length)
		{
			if (tmr != null)
			{
				typeTimer = null;
				tmr.cancel();
				tmr.destroy();
			}
			finishedText = true;
		}
	}

	public function killTheTimer():Void
	{
		if (typeTimer != null)
		{
			typeTimer.cancel();
			typeTimer.destroy();
		}
		typeTimer = null;
	}
}

// TODO Edit the XMLs for the text to correct the offsets of some characters instead of hard-coding them
class AlphaCharacter extends FlxSprite
{
	/**
	 * This value controls how far down the letters are moved when they are aligned at the bottom instead of at the top
	 */
	private static final Y_CORRECTION:Float = 90;

	public var row:Int = 0;

	private var textSize:Float = 1;

	public function new(x:Float, y:Float, textSize:Float, ?bold:Bool = false)
	{
		super(x, y);

		frames = Paths.getSparrowAtlas(bold ? 'fonts/bold' : 'fonts/default');

		setGraphicSize(Std.int(width * textSize));
		updateHitbox();
		this.textSize = textSize;
		antialiasing = Options.save.data.globalAntialiasing;
	}

	public function createBoldLetter(letter:String):Void
	{
		animation.addByPrefix(letter, letter.toUpperCase(), 24);
		animation.play(letter);
		updateHitbox();

		// y = Y_CORRECTION - height;
		// y += row * 60;
	}

	public function createBoldNumber(letter:String):Void
	{
		// TODO Surgically insert the bold letters from the original Psych alphabet into the PolyEngine alphabet
		frames = Paths.getSparrowAtlas('fonts/alphabet');

		// animation.addByPrefix(letter, letter, 24);
		animation.addByPrefix(letter, 'bold$letter', 24);
		animation.play(letter);
		updateHitbox();

		// y = Y_CORRECTION - height;
		// y += row * 60;
	}

	public function createBoldSymbol(letter:String):Void
	{
		animation.addByPrefix(letter, letter, 24);
		animation.play(letter);
		updateHitbox();

		// y = Y_CORRECTION - height;
		// y += row * 60;
		// switch (letter)
		// {
		// 	case "'", '^', '“', '”':
		// 		y -= 25 * textSize;
		// 	case '-':
		// 		y -= 16 * textSize;
		// }
	}

	public function createLetter(letter:String):Void
	{
		animation.addByPrefix(letter, letter, 24);
		animation.play(letter);
		updateHitbox();

		y = Y_CORRECTION - height;
		// y += row * 60;
	}

	public function createNumber(letter:String):Void
	{
		animation.addByPrefix(letter, letter, 24);
		animation.play(letter);
		updateHitbox();

		y = Y_CORRECTION - height;
		// y += row * 60;
	}

	public function createSymbol(letter:String):Void
	{
		animation.addByPrefix(letter, letter, 24);
		animation.play(letter);
		updateHitbox();

		y = Y_CORRECTION - height;
		// y += row * 60;
		switch (letter)
		{
			case "'", '^', '“', '”':
				y -= 25 * textSize;
			case '-':
				y -= 16 * textSize;
		}
	}
}
