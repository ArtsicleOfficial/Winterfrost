package misc;

import flixel.FlxSprite;
import flixel.util.FlxColor;

class Light extends FlxSprite
{
	public var size:Int;

	public function new(x:Float, y:Float, size:Int, color:FlxColor = 0xFFEE77)
	{
		super(x, y);
		this.size = size;
		this.setColorTransform(color.redFloat, color.greenFloat, color.blueFloat);
		this.loadGraphic("assets/images/lightbright.png", true, 50, 50);
		this.animation.add("flicker", [0, 1, 2, 1], 5);
		this.animation.play("flicker");
		this.setGraphicSize(size, size);
		this.updateHitbox();
	}

	// setsPosition on this element but from the center instead of top left
	public function position(x:Float, y:Float)
	{
		this.setPosition(x - size / 2, y - size / 2);
	}
}
