package;

#if newgrounds
import flixel.FlxG;
import flixel.util.FlxSignal;
import flixel.util.FlxTimer;
import io.newgrounds.Call;
import io.newgrounds.NG;
import io.newgrounds.objects.Medal;
import io.newgrounds.objects.Score;
import io.newgrounds.objects.ScoreBoard;
import io.newgrounds.objects.events.Response;
import io.newgrounds.objects.events.Result.GetCurrentVersionResult;
import openfl.Lib;

using StringTools;

// In case I want to reimplement this

/**
 * MADE BY GEOKURELI THE LEGENED GOD HERO MVP
 */
class NGio
{
	public static var isLoggedIn:Bool = false;
	public static var scoreboardsLoaded:Bool = false;

	public static var scoreboardArray:Array<Score> = [];

	public static var ngDataLoaded(default, null):FlxSignal = new FlxSignal();
	public static var ngScoresLoaded(default, null):FlxSignal = new FlxSignal();

	public static var GAME_VER:String = '';
	public static var GAME_VER_NUMS:String = '';
	public static var gotOnlineVer:Bool = false;

	public static function noLogin(api:String):Void
	{
		Debug.logTrace('INIT NOLOGIN');
		GAME_VER = 'v${Lib.application.meta.get('version')}';

		if (api.length != 0)
		{
			NG.create(api);

			new FlxTimer().start(2, function(tmr:FlxTimer)
			{
				var call:Call<GetCurrentVersionResult> = NG.core.calls.app.getCurrentVersion(GAME_VER)
					.addDataHandler(function(response:Response<GetCurrentVersionResult>)
					{
						GAME_VER = response.result.data.currentVersion;
						GAME_VER_NUMS = GAME_VER.split(' ')[0].trim();
						Debug.logTrace('CURRENT NG VERSION: $GAME_VER');
						Debug.logTrace('CURRENT NG VERSION: $GAME_VER_NUMS');
						gotOnlineVer = true;
					});

				call.send();
			});
		}
	}

	public static inline function postScore(score:Int = 0, song:String):Void
	{
		if (isLoggedIn)
		{
			for (id in NG.core.scoreBoards.keys())
			{
				var board:ScoreBoard = NG.core.scoreBoards.get(id);

				if (song == board.name)
				{
					board.postScore(score, 'Uhh meow?');
				}

				// Debug.logTrace('Loaded scoreboard ID:$id, name:${board.name}');
			}
		}
	}

	public static inline function logEvent(event:String):Void
	{
		NG.core.calls.event.logEvent(event).send();
		Debug.logTrace('Should have logged: $event');
	}

	public static inline function unlockMedal(id:Int):Void
	{
		if (isLoggedIn)
		{
			var medal:Medal = NG.core.medals.get(id);
			if (!medal.unlocked)
				medal.sendUnlock();
		}
	}

	public function new(api:String, encKey:String, ?sessionId:String)
	{
		Debug.logTrace('Connecting to newgrounds');

		NG.createAndCheckSession(api, sessionId);

		NG.core.verbose = true;
		// Set the encryption cipher/format to RC4/Base64. AES128 and Hex are not implemented yet
		NG.core.initEncryption(encKey); // Found in you NG project view

		Debug.logTrace(NG.core.attemptingLogin);

		if (NG.core.attemptingLogin)
		{
			/*
			 * a session_id was found in the loadervars, this means the user is playing on newgrounds.com
			 * and we should login shortly. lets wait for that to happen
			 */
			Debug.logTrace('Attempting login');
			NG.core.onLogin.add(onNGLogin);
		}
		else
		{
			/*
			 * They are NOT playing on newgrounds.com, no session id was found. We must start one manually, if we want to.
			 * Note: This will cause a new browser window to pop up where they can log in to newgrounds
			 */
			NG.core.requestLogin(onNGLogin);
		}
	}

	private function onNGLogin():Void
	{
		Debug.logTrace('logged in! user:${NG.core.user.name}');
		isLoggedIn = true;
		FlxG.save.data.sessionId = NG.core.sessionId;
		// FlxG.save.flush();
		// Load medals then call onNGMedalFetch()
		NG.core.requestMedals(onNGMedalFetch);

		// Load Scoreboards hten call onNGBoardsFetch()
		NG.core.requestScoreBoards(onNGBoardsFetch);

		ngDataLoaded.dispatch();
	}

	// --- MEDALS
	private function onNGMedalFetch():Void
	{
		/*
			// Reading medal info
			for (id in NG.core.medals.keys())
			{
				var medal:Medal = NG.core.medals.get(id);
				Debug.logTrace('loaded medal id:$id, name:${medal.name}, description:${medal.description}');
			}

			// Unlocking medals
			var unlockingMedal:Medal = NG.core.medals.get(54352); // medal ids are listed in your NG project viewer
			if (!unlockingMedal.unlocked)
				unlockingMedal.sendUnlock();
		 */
	}

	// --- SCOREBOARDS
	private function onNGBoardsFetch():Void
	{
		/*
			// Reading medal info
			for (id in NG.core.scoreBoards.keys())
			{
				var board:ScoreBoard = NG.core.scoreBoards.get(id);
				Debug.logTrace('Loaded scoreboard ID:$id, name:${board.name}');
			}
		 */
		// var board:ScoreBoard = NG.core.scoreBoards.get(8004); // ID found in NG project view

		// // Posting a score thats OVER 9000!
		// board.postScore(FlxG.random.int(0, 1000));

		// // --- To view the scores you first need to select the range of scores you want to see ---

		// // add an update listener so we know when we get the new scores
		// board.onUpdate.add(onNGScoresFetch);
		// Debug.logTrace('Should have gotten score by now');
		// board.requestScores(20); // get the best 10 scores ever logged
		// // more info on scores --- http://www.newgrounds.io/help/components/#scoreboard-getscores
	}

	private function onNGScoresFetch():Void
	{
		scoreboardsLoaded = true;

		ngScoresLoaded.dispatch();
		/*
			for (score in NG.core.scoreBoards.get(8737).scores)
			{
				Debug.logTrace('Score loaded user:${score.user.name}, score:${score.formattedValue}');
			}
		 */

		// var board:ScoreBoard = NG.core.scoreBoards.get(8004); // ID found in NG project view
		// board.postScore(HighScore.score);

		// scoreboardArray = NG.core.scoreBoards.get(8004).scores;
	}
}
#end
