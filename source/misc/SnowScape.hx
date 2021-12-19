package misc;

import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;

class SnowScape extends FlxTypedGroup<SnowFlake>
{
	public static inline final TIME_FOR_SNOWFLAKES = 0.1;

	public var snowflakeCounter:Float = 0;

	public function new(amt:Int, depthMultiplier:Float = 1, color:FlxColor = 0xFFFFFFFF, windAmt:Float = 1)
	{
		super();

		for (i in 0...amt)
		{
			add(new SnowFlake(true, depthMultiplier, color, windAmt));
		}
	}

	public function pause()
	{
		forEachExists(function(entity:SnowFlake)
		{
			entity.paused = true;
			entity.speed = 1;
		});
	}

	public function unpause()
	{
		forEachExists(function(entity:SnowFlake)
		{
			entity.paused = false;
			entity.speed = 0;
		});
	}
}
