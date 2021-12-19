package misc;

import flixel.math.FlxPoint;

class Utility
{
	public static inline function lerp(x:Float, y:Float, a:Float):Float
	{
		return x + (y - x) * a;
	}

	public static inline function lerpPos(from:FlxPoint, to:FlxPoint, a)
	{
		return new FlxPoint(lerp(from.x, to.x, a), lerp(from.y, to.y, a));
	}
}
