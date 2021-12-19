package misc;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;

class Shopkeeper extends FlxTypedGroup<FlxSprite>
{
	public static final GREETINGS = [
		"Hello!",
		"Welcome!",
		"Enjoy your stay!",
		"Watch my wares!",
		"Let's fix up your lighter!"
	];
	public static final LEAVINGS = ["Good luck!", "Come again!", "Stay warm!", "Goodbye!", "See you later!"];

	public var shopID:Int;

	public var keeper:FlxSprite;
	public var text:MessagePopup;

	public function new(x:Float, y:Float, shopID:Int, flipToFaceRight:Bool)
	{
		super();
		keeper = new FlxSprite(x, y);
		keeper.loadGraphic("assets/images/shopkeeper.png", true, 24, 48);
		keeper.animation.add("idle", [0, 1], 1);
		keeper.animation.play("idle");

		keeper.setFacingFlip(LEFT, false, false);
		keeper.setFacingFlip(RIGHT, true, false);
		if (flipToFaceRight)
		{
			keeper.facing = RIGHT;
		}

		text = new MessagePopup(x - 80 + keeper.width / 2, y - 16, "", 1);

		add(keeper);
		add(text);

		this.shopID = shopID;
	}

	public function say(string:String)
	{
		FlxG.sound.play("assets/sounds/coin.mp3", 1, false);
		this.text.fadeInOut(string);
		text.y = keeper.y - text.height;
	}
}
