package;

import haxe.Exception;
import haxe.Json;
import haxe.io.Path;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

class Ana
{
	public var hitTime:Float;
	public var nearestNote:Array<Any>;
	public var hit:Bool;
	public var hitJudge:String;
	public var key:Int;

	public function new(_hitTime:Float, _nearestNote:Array<Any>, _hit:Bool, _hitJudge:String, _key:Int)
	{
		hitTime = _hitTime;
		nearestNote = _nearestNote;
		hit = _hit;
		hitJudge = _hitJudge;
		key = _key;
	}
}

class Analysis
{
	public var anaArray:Array<Ana>;

	public function new()
	{
		anaArray = [];
	}
}

typedef ReplayDef =
{
	var replayGameVer:String;
	var timestamp:Date;
	var songId:String;
	var songName:String;
	var songDiff:Int;
	var songNotes:Array<Array<Any>>;
	var songJudgements:Array<String>;
	var noteSpeed:Float;
	var chartPath:String;
	var isDownscroll:Bool;
	var sf:Int;
	var sm:Bool;
	var ana:Analysis;
}

class Replay
{
	public static final REPLAY_VERSION:String = '1.2'; // replay file version

	public var path:String = '';
	public var replay:ReplayDef;

	public function new(path:String)
	{
		this.path = path;
		replay = {
			songId: 'nosong',
			songName: 'No Song Found',
			songDiff: 1,
			noteSpeed: 1.5,
			isDownscroll: false,
			songNotes: [],
			replayGameVer: REPLAY_VERSION,
			chartPath: '',
			sm: false,
			timestamp: Date.now(),
			sf: Options.save.data.safeFrames,
			ana: new Analysis(),
			songJudgements: []
		};
	}

	public static function loadReplay(path:String):Replay
	{
		var rep:Replay = new Replay(path);

		rep.loadFromJson();

		Debug.logTrace('Basic replay data:\nSong Name: ${rep.replay.songName}\nSong Diff: ${rep.replay.songDiff}');

		return rep;
	}

	public function saveReplay(notearray:Array<Array<Any>>, judge:Array<String>, ana:Analysis):Void
	{
		var chartPath:String = #if FEATURE_STEPMANIA PlayState.isSM ? Path.join([PlayState.pathToSm, Path.withExtension('converted', Paths.JSON_EXT)]) : #end
		'';

		var json:ReplayDef = {
			songId: PlayState.song.songId,
			songName: PlayState.song.songName,
			songDiff: PlayState.storyDifficulty,
			chartPath: chartPath,
			sm: PlayState.isSM,
			timestamp: Date.now(),
			replayGameVer: REPLAY_VERSION,
			sf: Options.save.data.safeFrames,
			noteSpeed: PlayState.instance.songSpeed,
			isDownscroll: Options.save.data.downScroll,
			songNotes: notearray,
			songJudgements: judge,
			ana: ana
		};

		var data:String = Json.stringify(json, '\t');

		var time:Float = Date.now().getTime();

		path = Path.withExtension('replay-${PlayState.song.songId}-time$time', 'kadeReplay'); // for score screen shit

		#if sys
		if (!Paths.fileSystem.exists('assets/replays'))
			FileSystem.createDirectory('assets/replays');
		File.saveContent(Path.join(['assets/replays', path]), data);

		loadFromJson();

		replay.ana = ana;
		#end
	}

	public function loadFromJson():Void
	{
		Debug.logTrace('Loading ${Path.join(['assets/replays', path])} replay...');
		try
		{
			var repl:ReplayDef = Paths.getJsonDirect(Path.join(['assets/replays', path]));
			replay = repl;
		}
		catch (e:Exception)
		{
			Debug.logError('Error loading replay: ${e.message}');
		}
	}
}
