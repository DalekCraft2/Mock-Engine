package;

import flixel.FlxSprite;
import haxe.io.Path;

typedef MenuCharacterDef =
{
	var image:String;
	var ?scale:Float;
	var ?position:Array<Int>;
	var idleAnim:String;
	var confirmAnim:String;
	var ?flipX:Bool;
	var ?loopIdle:Bool;
	var ?dances:Bool;
	var ?danceLeftIndices:Array<Int>;
	var ?danceRightIndices:Array<Int>;
}

class MenuCharacter extends FlxSprite
{
	/**
	 * The menu character ID used in case the requested menu character is missing.
	 */
	public static inline final DEFAULT_MENU_CHARACTER:String = 'bf';

	public var id:String;

	public var idleAnim:String = '';
	public var confirmAnim:String = '';
	public var loopIdle:Bool = false;
	public var dances:Bool = false;

	private var danceLeftIndices:Array<Int> = [];
	private var danceRightIndices:Array<Int> = [];
	private var dancingLeft:Bool = false;

	private var hasConfirmAnimation:Bool = false;

	public function new(x:Float, id:String = DEFAULT_MENU_CHARACTER)
	{
		super(x);

		changeCharacter(id);
	}

	public function changeCharacter(id:String = DEFAULT_MENU_CHARACTER):Void
	{
		if (id == this.id)
			return;

		this.id = id;
		antialiasing = Options.save.data.globalAntialiasing;
		visible = true;

		scale.set(1, 1);
		updateHitbox();

		hasConfirmAnimation = false;
		switch (id)
		{
			case '':
				visible = false;
			default:
				var menuCharacterDef:MenuCharacterDef = Paths.getJson(Path.join(['menucharacters', id]));
				if (menuCharacterDef == null)
				{
					Debug.logError('Could not find menu character data for menu character "$id"; using default');
					menuCharacterDef = Paths.getJson(Path.join(['menucharacters', DEFAULT_MENU_CHARACTER]));
				}

				frames = Paths.getSparrowAtlas(Path.join(['menucharacters', menuCharacterDef.image]));

				if (menuCharacterDef.idleAnim != null)
				{
					idleAnim = menuCharacterDef.idleAnim;
				}
				else
				{
					idleAnim = '';
				}

				if (menuCharacterDef.confirmAnim != null)
				{
					confirmAnim = menuCharacterDef.confirmAnim;
				}
				else
				{
					confirmAnim = '';
				}

				if (menuCharacterDef.flipX != null)
				{
					flipX = menuCharacterDef.flipX;
				}
				else
				{
					flipX = false;
				}

				if (menuCharacterDef.scale != null)
				{
					scale.set(menuCharacterDef.scale, menuCharacterDef.scale);
					updateHitbox();
				}
				else
				{
					scale.set(1, 1);
				}

				if (menuCharacterDef.position != null)
				{
					offset.set(menuCharacterDef.position[0], menuCharacterDef.position[1]);
				}
				else
				{
					offset.set();
				}

				if (menuCharacterDef.loopIdle != null)
				{
					loopIdle = menuCharacterDef.loopIdle;
				}
				else
				{
					loopIdle = false;
				}

				if (menuCharacterDef.dances != null)
				{
					dances = menuCharacterDef.dances;
				}
				else
				{
					dances = false;
				}

				if (dances)
				{
					if (menuCharacterDef.danceLeftIndices != null)
					{
						danceLeftIndices = menuCharacterDef.danceLeftIndices;
					}
					else
					{
						danceLeftIndices = [];
					}
					if (menuCharacterDef.danceRightIndices != null)
					{
						danceRightIndices = menuCharacterDef.danceRightIndices;
					}
					else
					{
						danceRightIndices = [];
					}

					animation.addByIndices('danceLeft', idleAnim, danceLeftIndices, '', 24, false);
					animation.addByIndices('danceRight', idleAnim, danceRightIndices, '', 24, false);
				}
				else
				{
					animation.addByPrefix('idle', idleAnim, 24, loopIdle);
				}
				if (confirmAnim != null && confirmAnim != idleAnim)
				{
					animation.addByPrefix('confirm', confirmAnim, 24, false);
				}

				if (loopIdle)
				{
					animation.play('idle');
				}
				else
				{
					bopHead(true);
				}
		}
	}

	public function bopHead(lastFrame:Bool = false):Void
	{
		if (dances)
		{
			dancingLeft = !dancingLeft;

			if (dancingLeft)
				animation.play('danceLeft', true);
			else
				animation.play('danceRight', true);
		}
		else if (id == '')
		{
			// Don't try to play an animation on an invisible character.
			return;
		}
		else
		{
			if (loopIdle)
				return;

			// doesn't dance so we do da normal animation
			if (animation.name == 'confirm')
				return;
			animation.play('idle', true);
		}
		if (lastFrame)
		{
			animation.finish();
		}
	}

	public function playConfirmAnim():Void
	{
		if (animation.exists('confirm'))
			animation.play('confirm');
	}
}
