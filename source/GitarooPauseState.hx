package;

import flixel.FlxG;
import flixel.FlxSprite;

class GitarooPauseState extends MusicBeatState
{
	private var replayButton:FlxSprite;
	private var cancelButton:FlxSprite;

	private var replaySelect:Bool = false;

	override public function create():Void
	{
		super.create();

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.getGraphic('pauseAlt/pauseBG'));
		add(bg);

		var bf:FlxSprite = new FlxSprite(0, 30);
		bf.frames = Paths.getSparrowAtlas('pauseAlt/bfLol');
		bf.animation.addByPrefix('lol', 'funnyThing', 13);
		bf.animation.play('lol');
		bf.screenCenter(X);
		add(bf);

		replayButton = new FlxSprite(FlxG.width * 0.28, FlxG.height * 0.7);
		replayButton.frames = Paths.getSparrowAtlas('pauseAlt/pauseUI');
		replayButton.animation.addByPrefix('selected', 'bluereplay', 0, false);
		replayButton.animation.appendByPrefix('selected', 'yellowreplay');
		replayButton.animation.play('selected');
		add(replayButton);

		cancelButton = new FlxSprite(FlxG.width * 0.58, replayButton.y);
		cancelButton.frames = Paths.getSparrowAtlas('pauseAlt/pauseUI');
		cancelButton.animation.addByPrefix('selected', 'bluecancel', 0, false);
		cancelButton.animation.appendByPrefix('selected', 'cancelyellow');
		cancelButton.animation.play('selected');
		add(cancelButton);

		changeThing();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (controls.UI_LEFT_P || controls.UI_RIGHT_P)
			changeThing();

		if (controls.ACCEPT)
		{
			if (replaySelect)
			{
				FlxG.switchState(new PlayState());
			}
			else
			{
				PlayStateChangeables.practiceMode = false;
				PlayState.changedDifficulty = false;
				PlayState.seenCutscene = false;
				PlayState.deathCounter = 0;
				PlayStateChangeables.botPlay = false;
				FlxG.switchState(new MainMenuState());
			}
		}
	}

	private function changeThing():Void
	{
		replaySelect = !replaySelect;

		if (replaySelect)
		{
			cancelButton.animation.curAnim.curFrame = 0;
			replayButton.animation.curAnim.curFrame = 1;
		}
		else
		{
			cancelButton.animation.curAnim.curFrame = 1;
			replayButton.animation.curAnim.curFrame = 0;
		}
	}
}
