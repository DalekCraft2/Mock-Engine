package editors;

import Note.NoteDef;
import Section.SectionDef;
import Song.SongDef;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import haxe.io.Path;
import openfl.events.KeyboardEvent;

using StringTools;

// TODO Ensure that this and EditorScript have the most up-to-date code from their respective copied classes (PlayState and FunkinScript)
// Yes, this is mostly a copy of PlayState, it's kinda dumb to make a direct copy of it but... ehhh
class EditorPlayState extends MusicBeatState
{
	private static final COMBO_X:Float = 400;
	private static final COMBO_Y:Float = 340;

	public static var instance:EditorPlayState;

	private var vocals:FlxSound;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];

	private var strumLine:FlxSprite;
	private var comboGroup:FlxTypedGroup<FlxSprite>;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	private var generatedMusic:Bool = false;

	private var startOffset:Float = 0;
	private var startPos:Float = 0;

	public function new(startPos:Float)
	{
		super();

		this.startPos = startPos;
		Conductor.songPosition = startPos - startOffset;

		startOffset = Conductor.crochet;
		timerToStart = startOffset;
	}

	private var scoreTxt:FlxText;
	private var stepTxt:FlxText;
	private var beatTxt:FlxText;

	private var timerToStart:Float = 0;
	private var noteTypeMap:Map<String, Bool> = [];

	// Less laggy controls
	private var keysArray:Array<Array<FlxKey>>;

	override public function create():Void
	{
		super.create();

		instance = this;

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.getGraphic('menuDesat'));
		bg.scrollFactor.set();
		bg.color = FlxColor.fromHSB(FlxG.random.int(0, 359), FlxG.random.float(0, 0.8), FlxG.random.float(0.3, 1));
		add(bg);

		keysArray = [
			Options.copyKey(Options.save.data.keyBinds.get('note_left')),
			Options.copyKey(Options.save.data.keyBinds.get('note_down')),
			Options.copyKey(Options.save.data.keyBinds.get('note_up')),
			Options.copyKey(Options.save.data.keyBinds.get('note_right'))
		];

		strumLine = new FlxSprite(Options.save.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X, 50).makeGraphic(FlxG.width, 10);
		if (Options.save.data.downScroll)
			strumLine.y = FlxG.height - 150;
		strumLine.scrollFactor.set();

		comboGroup = new FlxTypedGroup();
		add(comboGroup);

		strumLineNotes = new FlxTypedGroup();
		opponentStrums = new FlxTypedGroup();
		playerStrums = new FlxTypedGroup();
		add(strumLineNotes);

		generateStaticArrows(0);
		generateStaticArrows(1);

		grpNoteSplashes = new FlxTypedGroup();
		add(grpNoteSplashes);

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;

		if (PlayState.song.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.getVoices(PlayState.song.songId));
		else
			vocals = new FlxSound();

		generateSong(PlayState.song.songId);
		#if FEATURE_SCRIPTS
		if (Options.save.data.loadScripts)
		{
			for (notetype in noteTypeMap.keys())
			{
				var scriptPath:String = Paths.script(Path.join(['notetypes', notetype]));
				if (Paths.exists(scriptPath))
				{
					var script:EditorScript = new EditorScript(scriptPath);
					new FlxTimer().start(0.1, (tmr:FlxTimer) ->
					{
						script.stop();
						script = null;
					});
				}
			}
		}
		#end
		noteTypeMap.clear();
		noteTypeMap = null;

		scoreTxt = new FlxText(0, FlxG.height - 50, FlxG.width, 'Hits: 0 | Misses: 0', 20);
		scoreTxt.setFormat(Paths.font('vcr.ttf'), scoreTxt.size, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !Options.save.data.hideHud;
		add(scoreTxt);

		beatTxt = new FlxText(10, 610, FlxG.width, 'Beat: 0', 20);
		beatTxt.setFormat(Paths.font('vcr.ttf'), beatTxt.size, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		beatTxt.scrollFactor.set();
		beatTxt.borderSize = 1.25;
		add(beatTxt);

		stepTxt = new FlxText(10, 640, FlxG.width, 'Step: 0', 20);
		stepTxt.setFormat(Paths.font('vcr.ttf'), stepTxt.size, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		stepTxt.scrollFactor.set();
		stepTxt.borderSize = 1.25;
		add(stepTxt);

		var tipText:FlxText = new FlxText(10, FlxG.height - 24, 0, 'Press ESC to Go Back to Chart Editor', 16);
		tipText.setFormat(Paths.font('vcr.ttf'), tipText.size, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		tipText.borderSize = 2;
		tipText.scrollFactor.set();
		add(tipText);
		FlxG.mouse.visible = false;

		if (!Options.save.data.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.ESCAPE)
		{
			FlxG.sound.music.pause();
			vocals.pause();
			LoadingState.loadAndSwitchState(new editors.ChartEditorState());
		}

		if (startingSong)
		{
			timerToStart -= elapsed * 1000;
			Conductor.songPosition = startPos - timerToStart;
			if (timerToStart < 0)
			{
				startSong();
			}
		}
		else
		{
			Conductor.songPosition += elapsed * 1000;
		}

		var roundedSpeed:Float = FlxMath.roundDecimal(PlayState.song.speed, 2);
		if (unspawnNotes[0] != null)
		{
			var time:Float = 1500;
			if (roundedSpeed < 1)
				time /= roundedSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			var fakeCrochet:Float = (60 / PlayState.song.bpm) * 1000;
			notes.forEachAlive((daNote:Note) ->
			{
				/*
					if (daNote.y > FlxG.height)
					{
						daNote.active = false;
						daNote.visible = false;
					}
					else
					{
						daNote.visible = true;
						daNote.active = true;
					}
				 */

				// i am so fucking sorry for this if condition
				var strumX:Float = 0;
				var strumY:Float = 0;
				if (daNote.mustPress)
				{
					strumX = playerStrums.members[daNote.noteData].x;
					strumY = playerStrums.members[daNote.noteData].y;
				}
				else
				{
					strumX = opponentStrums.members[daNote.noteData].x;
					strumY = opponentStrums.members[daNote.noteData].y;
				}

				strumX += daNote.offsetX;
				strumY += daNote.offsetY;
				var center:Float = strumY + Note.STRUM_WIDTH / 2;

				if (daNote.copyX)
				{
					daNote.x = strumX;
				}
				if (daNote.copyY)
				{
					if (Options.save.data.downScroll)
					{
						daNote.y = (strumY + 0.45 * (Conductor.songPosition - daNote.strumTime) * roundedSpeed);
						if (daNote.isSustainNote)
						{
							// Jesus fuck this took me so much mother fucking time AAAAAAAAAA
							if (daNote.animation.curAnim.name.endsWith('end'))
							{
								daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * roundedSpeed + (46 * (roundedSpeed - 1));
								daNote.y -= 46 * (1 - (fakeCrochet / 600)) * roundedSpeed;
								if (PlayState.isPixelStage)
								{
									daNote.y += 8;
								}
								else
								{
									daNote.y -= 19;
								}
							}
							daNote.y += (Note.STRUM_WIDTH / 2) - (60.5 * (roundedSpeed - 1));
							daNote.y += 27.5 * ((PlayState.song.bpm / 100) - 1) * (roundedSpeed - 1);

							if (daNote.mustPress || !daNote.ignoreNote)
							{
								if (daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center
									&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
								{
									var clipRect:FlxRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
									clipRect.height = (center - daNote.y) / daNote.scale.y;
									clipRect.y = daNote.frameHeight - clipRect.height;

									daNote.clipRect = clipRect;
								}
							}
						}
					}
					else
					{
						daNote.y = (strumY - 0.45 * (Conductor.songPosition - daNote.strumTime) * roundedSpeed);

						if (daNote.mustPress || !daNote.ignoreNote)
						{
							if (daNote.isSustainNote
								&& daNote.y + daNote.offset.y * daNote.scale.y <= center
								&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
							{
								var clipRect:FlxRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
								clipRect.y = (center - daNote.y) / daNote.scale.y;
								clipRect.height -= clipRect.y;

								daNote.clipRect = clipRect;
							}
						}
					}
				}

				if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
				{
					if (PlayState.song.needsVoices)
						vocals.volume = 1;

					var time:Float = 0.15;
					if (daNote.isSustainNote && !daNote.animation.curAnim.name.endsWith('end'))
					{
						time += 0.15;
					}
					strumPlayAnim(true, daNote.noteData % 4, time);
					daNote.hitByOpponent = true;

					if (!daNote.isSustainNote)
					{
						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
				}

				var doKill:Bool = daNote.y < -daNote.height;
				if (Options.save.data.downScroll)
					doKill = daNote.y > FlxG.height;

				if (doKill)
				{
					if (daNote.mustPress)
					{
						if (daNote.tooLate || !daNote.wasGoodHit)
						{
							// Dupe note remove
							notes.forEachAlive((note:Note) ->
							{
								if (daNote != note
									&& daNote.mustPress
									&& daNote.noteData == note.noteData
									&& daNote.isSustainNote == note.isSustainNote
									&& Math.abs(daNote.strumTime - note.strumTime) < 10)
								{
									note.kill();
									notes.remove(note, true);
									note.destroy();
								}
							});

							if (!daNote.ignoreNote)
							{
								songMisses++;
								vocals.volume = 0;
							}
						}
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});
		}

		keyShit();
		scoreTxt.text = 'Hits: $songHits | Misses: $songMisses';
		beatTxt.text = 'Beat: $curBeat';
		stepTxt.text = 'Step: $curStep';
	}

	override public function destroy():Void
	{
		super.destroy();

		FlxG.sound.music.stop();
		vocals.stop();
		vocals.destroy();

		if (!Options.save.data.controllerMode)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		instance = null;
	}

	override public function onFocusLost():Void
	{
		super.onFocusLost();

		vocals.pause();
	}

	override public function onFocus():Void
	{
		super.onFocus();

		vocals.play();
	}

	override public function stepHit(step:Int):Void
	{
		super.stepHit(step);

		if (FlxG.sound.music.time > Conductor.songPosition + 20 || FlxG.sound.music.time < Conductor.songPosition - 20)
		{
			resyncVocals();
		}
	}

	override public function beatHit(beat:Int):Void
	{
		super.beatHit(beat);

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, Options.save.data.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}
	}

	private function sayGo():Void
	{
		var go:FlxSprite = new FlxSprite().loadGraphic(Paths.getGraphic('go'));
		go.scrollFactor.set();

		go.updateHitbox();

		go.screenCenter();
		go.antialiasing = Options.save.data.globalAntialiasing;
		add(go);
		FlxTween.tween(go, {y: go.y += 100, alpha: 0}, Conductor.crochet / 1000, {
			ease: FlxEase.cubeInOut,
			onComplete: (twn:FlxTween) ->
			{
				go.destroy();
			}
		});
		FlxG.sound.play(Paths.getSound('introGo'), 0.6);
	}

	private var songHits:Int = 0;
	private var songMisses:Int = 0;
	private var startingSong:Bool = true;

	private function generateSong(dataPath:String):Void
	{
		FlxG.sound.music.loadEmbedded(Paths.getInst(PlayState.song.songId), false);
		FlxG.sound.music.pause();
		FlxG.sound.music.onComplete = endSong;
		vocals.pause();

		var songDef:SongDef = PlayState.song;
		Conductor.changeBPM(songDef.bpm);

		notes = new FlxTypedGroup();
		add(notes);

		var sections:Array<SectionDef> = songDef.notes;
		for (section in sections)
		{
			for (sectionEntry in section.sectionNotes)
			{
				if (!Section.isEvent(sectionEntry))
				{ // Real notes
					var noteDef:NoteDef = sectionEntry;

					var strumTime:Float = noteDef.strumTime;
					if (strumTime >= startPos)
					{
						var noteData:Int = Std.int(noteDef.noteData % 4);

						var mustHitNote:Bool = section.mustHitSection;

						if (noteDef.noteData > 3)
						{
							mustHitNote = !section.mustHitSection;
						}

						var oldNote:Null<Note> = null;
						if (unspawnNotes.length > 0)
							oldNote = unspawnNotes[unspawnNotes.length - 1];
						var note:Note = new Note(strumTime, noteData, oldNote);
						note.mustPress = mustHitNote;
						note.sustainLength = noteDef.sustainLength;
						note.noteType = noteDef.noteType;
						if (!Std.isOfType(noteDef.noteType, String))
							note.noteType = ChartEditorState.NOTE_TYPES[noteDef.noteType]; // Backward compatibility + compatibility with Week 7 charts
						note.scrollFactor.set();

						var sustainLength:Float = note.sustainLength / Conductor.stepCrochet;
						unspawnNotes.push(note);

						var floorSustain:Int = Math.floor(sustainLength);
						if (floorSustain > 0)
						{
							for (sustainFactor in 0...floorSustain + 1)
							{
								oldNote = unspawnNotes[unspawnNotes.length - 1];

								var sustainNote:Note = new Note(strumTime
									+ (Conductor.stepCrochet * sustainFactor)
									+ (Conductor.stepCrochet / FlxMath.roundDecimal(PlayState.song.speed, 2)),
									noteData, oldNote, true);
								sustainNote.mustPress = mustHitNote;
								sustainNote.noteType = note.noteType;
								sustainNote.scrollFactor.set();
								unspawnNotes.push(sustainNote);

								if (sustainNote.mustPress)
								{
									sustainNote.x += FlxG.width / 2; // general offset
								}
								else if (Options.save.data.middleScroll)
								{
									sustainNote.x += 310;
									if (noteData > 1)
									{ // Up and Right
										sustainNote.x += FlxG.width / 2 + 25;
									}
								}
							}
						}

						if (note.mustPress)
						{
							note.x += FlxG.width / 2; // general offset
						}
						else if (Options.save.data.middleScroll)
						{
							note.x += 310;
							if (noteData > 1) // Up and Right
							{
								note.x += FlxG.width / 2 + 25;
							}
						}

						if (!noteTypeMap.exists(note.noteType))
						{
							noteTypeMap.set(note.noteType, true);
						}
					}
				}
			}
		}

		unspawnNotes.sort(sortByShit);
		generatedMusic = true;
	}

	private function startSong():Void
	{
		startingSong = false;
		FlxG.sound.music.time = startPos;
		FlxG.sound.music.play();
		FlxG.sound.music.volume = 1;
		vocals.volume = 1;
		vocals.time = startPos;
		vocals.play();
	}

	private function sortByShit(obj1:Note, obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, obj1.strumTime, obj2.strumTime);
	}

	private function endSong():Void
	{
		LoadingState.loadAndSwitchState(new editors.ChartEditorState());
	}

	private function resyncVocals():Void
	{
		vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
	}

	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		// Debug.logTrace('Pressed: $eventKey');

		if (key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || Options.save.data.controllerMode))
		{
			if (generatedMusic)
			{
				// more accurate hit time for the ratings?
				var lastTime:Float = Conductor.songPosition;
				Conductor.songPosition = FlxG.sound.music.time;

				var canMiss:Bool = !Options.save.data.ghostTapping;

				// heavily based on my own code LOL if it aint broke dont fix it
				var pressNotes:Array<Note> = [];
				var notesStopped:Bool = false;

				// Debug.logTrace('Test!');
				var sortedNotesList:Array<Note> = [];
				notes.forEachAlive((daNote:Note) ->
				{
					if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit)
					{
						if (daNote.noteData == key && !daNote.isSustainNote)
						{
							// Debug.logTrace('Pushed note!');
							sortedNotesList.push(daNote);
						}
						canMiss = true;
					}
				});
				sortedNotesList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

				if (sortedNotesList.length > 0)
				{
					for (epicNote in sortedNotesList)
					{
						for (doubleNote in pressNotes)
						{
							if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1)
							{
								doubleNote.kill();
								notes.remove(doubleNote, true);
								doubleNote.destroy();
							}
							else
								notesStopped = true;
						}

						// eee jack detection before was not super good
						if (!notesStopped)
						{
							goodNoteHit(epicNote);
							pressNotes.push(epicNote);
						}
					}
				}
				else if (canMiss && !Options.save.data.ghostTapping)
				{
					noteMiss(key);
				}

				// more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
				Conductor.songPosition = lastTime;
			}

			var spr:StrumNote = playerStrums.members[key];
			if (spr != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
		}
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		if (key > -1)
		{
			var spr:StrumNote = playerStrums.members[key];
			if (spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
		}
		// Debug.logTrace('Released: $controlArray');
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if (key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if (key == keysArray[i][j])
					{
						return i;
					}
				}
			}
		}
		return -1;
	}

	private function keyShit():Void
	{
		// HOLDING
		var up:Bool = controls.NOTE_UP;
		var right:Bool = controls.NOTE_RIGHT;
		var down:Bool = controls.NOTE_DOWN;
		var left:Bool = controls.NOTE_LEFT;
		var controlHoldArray:Array<Bool> = [left, down, up, right];

		// TODO: Find a better way to handle controller inputs, this should work for now
		if (Options.save.data.controllerMode)
		{
			var controlArray:Array<Bool> = [
				controls.NOTE_LEFT_P,
				controls.NOTE_DOWN_P,
				controls.NOTE_UP_P,
				controls.NOTE_RIGHT_P
			];
			if (controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if (controlArray[i])
						onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
				}
			}
		}

		if (generatedMusic)
		{
			// rewritten inputs???
			notes.forEachAlive((daNote:Note) ->
			{
				// hold note functions
				if (daNote.isSustainNote && controlHoldArray[daNote.noteData] && daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit)
				{
					goodNoteHit(daNote);
				}
			});
		}

		// TODO: Find a better way to handle controller inputs, this should work for now
		if (Options.save.data.controllerMode)
		{
			var controlArray:Array<Bool> = [
				controls.NOTE_LEFT_R,
				controls.NOTE_DOWN_R,
				controls.NOTE_UP_R,
				controls.NOTE_RIGHT_R
			];
			if (controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if (controlArray[i])
						onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
				}
			}
		}
	}

	private var combo:Int = 0;

	private function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			switch (note.noteType)
			{
				case 'Hurt Note': // Hurt note
					noteMiss(note.noteData);
					--songMisses;
					if (!note.isSustainNote)
					{
						if (!note.noteSplashDisabled)
						{
							spawnNoteSplashOnNote(note);
						}
					}

					note.wasGoodHit = true;
					vocals.volume = 0;

					if (!note.isSustainNote)
					{
						note.kill();
						notes.remove(note, true);
						note.destroy();
					}
					return;
			}

			if (!note.isSustainNote)
			{
				popUpScore(note);
				combo += 1;
				songHits++;
				if (combo > 9999)
					combo = 9999;
			}

			playerStrums.forEach((spr:StrumNote) ->
			{
				if (note.noteData == spr.ID)
				{
					spr.playAnim('confirm', true);
				}
			});

			note.wasGoodHit = true;
			vocals.volume = 1;

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	private function noteMiss(direction:Int = 1):Void
	{
		combo = 0;

		songMisses++;

		FlxG.sound.play(Paths.getRandomSound('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
		vocals.volume = 0;
	}

	private function popUpScore(?note:Note):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + Options.save.data.ratingOffset);

		vocals.volume = 1;

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(COMBO_X, COMBO_Y, 0, placement, 32);

		var rating:FlxSprite = new FlxSprite();

		var ratingName:String = 'sick';

		if (noteDiff > Conductor.safeZoneOffset * 0.75)
		{
			ratingName = 'shit';
		}
		else if (noteDiff > Conductor.safeZoneOffset * 0.5)
		{
			ratingName = 'bad';
		}
		else if (noteDiff > Conductor.safeZoneOffset * 0.25)
		{
			ratingName = 'good';
		}

		if (ratingName == 'sick' && !note.noteSplashDisabled)
		{
			spawnNoteSplashOnNote(note);
		}

		var pixelShitPart1:String = '';
		var pixelShitPart2:String = '';

		if (PlayState.isPixelStage)
		{
			pixelShitPart1 = 'weeb/pixelUI';
			pixelShitPart2 = '-pixel';
		}

		rating.loadGraphic(Paths.getGraphic(Path.join([pixelShitPart1, '$ratingName$pixelShitPart2'])));
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);
		rating.visible = !Options.save.data.hideHud;
		rating.x += Options.save.data.comboOffset[0];
		rating.y -= Options.save.data.comboOffset[1];

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.getGraphic(Path.join([pixelShitPart1, 'combo$pixelShitPart2'])));
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;
		comboSpr.visible = !Options.save.data.hideHud;
		comboSpr.x += Options.save.data.comboOffset[0];
		comboSpr.y -= Options.save.data.comboOffset[1];

		comboSpr.velocity.x += FlxG.random.int(1, 10);
		comboGroup.add(rating);

		if (!PlayState.isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = Options.save.data.globalAntialiasing;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = Options.save.data.globalAntialiasing;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * PlayState.PIXEL_ZOOM * 0.85));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * PlayState.PIXEL_ZOOM * 0.85));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		if (combo >= 1000)
		{
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		}
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var loopsDone:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.getGraphic(Path.join([pixelShitPart1, 'num$i$pixelShitPart2'])));
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * loopsDone) - 90;
			numScore.y += 80;

			numScore.x += Options.save.data.comboOffset[2];
			numScore.y -= Options.save.data.comboOffset[3];

			if (!PlayState.isPixelStage)
			{
				numScore.antialiasing = Options.save.data.globalAntialiasing;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * PlayState.PIXEL_ZOOM));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);
			numScore.visible = !Options.save.data.hideHud;

			if (combo >= 10 || combo == 0)
				insert(members.indexOf(strumLineNotes), numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: (tween:FlxTween) ->
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});

			loopsDone++;
		}
		// Debug.logTrace(combo);
		// Debug.logTrace(seperatedScore);

		coolText.text = Std.string(seperatedScore);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.001
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: (tween:FlxTween) ->
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});
	}

	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...NoteKey.createAll().length)
		{
			var targetAlpha:Float = 1;
			if (player < 1 && Options.save.data.middleScroll)
				targetAlpha = 0.35;

			var babyArrow:StrumNote = new StrumNote(Options.save.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X, strumLine.y, i,
				player);
			babyArrow.alpha = targetAlpha;

			if (player == 1)
			{
				playerStrums.add(babyArrow);
			}
			else
			{
				if (Options.save.data.middleScroll)
				{
					babyArrow.x += 310;
					if (i > 1)
					{ // Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
				opponentStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}

	// For Opponent's notes glow
	private function strumPlayAnim(isDad:Bool, id:Int, time:Float):Void
	{
		var spr:StrumNote;
		if (isDad)
		{
			spr = strumLineNotes.members[id];
		}
		else
		{
			spr = playerStrums.members[id];
		}

		if (spr != null)
		{
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	// Note splash shit, duh
	private function spawnNoteSplashOnNote(note:Note):Void
	{
		if (Options.save.data.noteSplashes && note != null)
		{
			var strum:StrumNote = playerStrums.members[note.noteData];
			if (strum != null)
			{
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
			}
		}
	}

	private function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note):Void
	{
		var skin:String = 'noteSplashes';
		if (PlayState.song.splashSkin != null && PlayState.song.splashSkin.length > 0)
			skin = PlayState.song.splashSkin;

		var hue:Float = Options.save.data.arrowHSV[data % 4][0] / 360;
		var sat:Float = Options.save.data.arrowHSV[data % 4][1] / 100;
		var brt:Float = Options.save.data.arrowHSV[data % 4][2] / 100;
		if (note != null)
		{
			skin = note.noteSplashTexture;
			hue = note.noteSplashHue;
			sat = note.noteSplashSat;
			brt = note.noteSplashBrt;
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, skin, hue, sat, brt);
		grpNoteSplashes.add(splash);
	}
}
