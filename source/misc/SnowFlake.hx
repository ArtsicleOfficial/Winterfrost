package misc;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxColorTransformUtil;
import flixel.util.FlxDirectionFlags;

class SnowFlake extends FlxSprite
{
	// How offscreen a snowflake should be to be respawned
	public static inline final PADDING = 50;
	// How offscreen a snowflake is on spawn
	public static inline final NEW_PADDING = 10;

	var counter:Float = Math.random() * 10;

	public var scrollAmt:Float = 0;

	public var snowColor:Int;
	public var depthMultiplier:Float;

	public var wind:Float;

	public var paused:Bool = false;

	public function new(randomPos:Bool = false, depthMultiplier:Float = 1, color:FlxColor = 0xFFFFFFFF, wind:Float = 1)
	{
		super(0, 0);
		this.snowColor = color;
		this.depthMultiplier = depthMultiplier;
		this.wind = wind;
		renew(Math.random() <= 0.5 ? UP : RIGHT);

		if (randomPos)
		{
			this.setPosition(Math.random() * FlxG.camera.width + offset.x, Math.random() * FlxG.camera.height + offset.y);
		}
	}

	public function renew(dir:FlxDirectionFlags)
	{
		this.scrollAmt = (Math.random() / 2 + 0.5) * depthMultiplier;
		this.scrollFactor.set(0, 0);
		this.makeGraphic(cast(Math.ceil(scrollAmt * 3), Int), cast(Math.ceil(scrollAmt * 3), Int), snowColor);
		if (dir == RIGHT)
		{
			this.x = FlxG.camera.width + NEW_PADDING;
			this.y = Math.random() * FlxG.camera.height;
		}
		else if (dir == UP)
		{
			this.x = Math.random() * FlxG.camera.width * 1.2;
			this.y = -NEW_PADDING;
		}
		else if (dir == DOWN)
		{
			this.x = Math.random() * FlxG.camera.width * 1.2;
			this.y = FlxG.camera.height + NEW_PADDING;
		}
		else if (dir == LEFT)
		{
			this.x = -NEW_PADDING;
			this.y = Math.random() * FlxG.camera.height;
		}

		this.velocity.set(wind * -72 * scrollAmt, 16 * scrollAmt);
		this.delta = FlxG.camera.scroll;
	}

	public var delta:FlxPoint = new FlxPoint(0, 0);

	public var speed:Float = 1;

	override public function update(elapsed:Float)
	{
		this.x -= (FlxG.camera.scroll.x - delta.x) * scrollAmt;
		this.y -= (FlxG.camera.scroll.y - delta.y) * scrollAmt;

		delta = new FlxPoint(FlxG.camera.scroll.x, FlxG.camera.scroll.y);

		if (paused)
		{
			if (speed == 1)
			{
				speed = 0.99;
			}
			speed -= (speed / 20);
			if (speed < 0.1)
			{
				speed = 0;
			}
			super.update(elapsed * speed);
			return;
		}
		counter += elapsed;
		this.velocity.add((Math.random() - 0.5 - Math.random() / 4) * scrollAmt, (Math.random() - 0.5 + Math.random() / 4) * scrollAmt);

		var screenPos = this.getScreenPosition();

		if (screenPos.x < -PADDING)
		{
			renew(RIGHT);
		}
		else if (screenPos.x > FlxG.camera.width + PADDING)
		{
			renew(LEFT);
		}
		else if (screenPos.y < -PADDING)
		{
			renew(DOWN);
		}
		else if (screenPos.y > FlxG.camera.height + PADDING)
		{
			renew(UP);
		}

		if (speed < 1)
		{
			if (speed == 0)
			{
				speed = 0.01;
			}
			speed = Math.min(1, speed + ((1 - speed) / 20));
		}
		super.update(elapsed * speed);
	}
}
