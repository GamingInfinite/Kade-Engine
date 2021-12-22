package;

import openfl.utils.Assets as OpenFlAssets;

using StringTools;

class CoolUtil
{
	public static var difficultyArray:Array<String> = [];
	public static var weekArray:Array<String> = [];

	public static var daPixelZoom:Float = 6;

	public static function difficultyFromInt(difficulty:Int):String
	{
		difficultyArray = []; // Jank Fix
		difficultyStuff();
		return difficultyArray[difficulty];
	}

	public static function intFromDifficulty(difficulty:String):Int
	{
		difficultyArray = []; // Jank Fix
		difficultyStuff();
		return difficultyArray.indexOf(difficulty);
	}

	public static function weekFromInt(week:Int)
	{
		weekArray = [];
		weekStuff();
		return weekArray[week];
	}

	public static function intFromWeek(week:String)
	{
		weekArray = [];
		weekStuff();
		return weekArray.indexOf(week);
	}

	public static function coolTextFile(path:String):Array<String>
	{
		var daList:Array<String> = OpenFlAssets.getText(path).trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	public static function coolStringFile(path:String):Array<String>
	{
		var daList:Array<String> = path.trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
		{
			dumbArray.push(i);
		}
		return dumbArray;
	}

	public static function getDiffArray()
	{
		difficultyArray = []; // Jank Fix
		difficultyStuff();
		return difficultyArray;
	}

	public static function getWeekArray()
	{
		weekArray = [];
		weekStuff();
		return weekArray;
	}

	static function weekStuff()
	{
		var tempArr = CoolUtil.coolTextFile(Paths.txt('data/weekList'));
		for (i in 0...tempArr.length)
		{
			var diffName = tempArr[i];

			weekArray.push(diffName);
		}
	}

	static function difficultyStuff()
	{
		var tempArr = CoolUtil.coolTextFile(Paths.txt('data/diffs'));
		for (i in 0...tempArr.length)
		{
			var diffName = tempArr[i];

			difficultyArray.push(diffName);
		}
	}
}
