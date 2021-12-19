package tiles;

import flixel.FlxG;
import flixel.FlxSprite;

class Trigger extends FlxSprite
{
	public var type:Int;

	public var data:String;
	public var checkpointId:Int;

	// Data for TriggerType.DIALOG: text to say
	// Data for TriggerType.MOVE_LEVEL: Level file name such as "level0.json;" must be located in assets/data/
	public function new(x:Float, y:Float, width:Float, height:Float, type:Int, data:String, checkpointId:Int = -1)
	{
		super(x, y);
		setSize(width, height);
		this.type = type;
		this.data = data;
		this.checkpointId = checkpointId;
		if (type == TriggerType.DIALOG)
		{
			this.visible = true;
			loadGraphic("assets/images/sign.png", true, 24, 24);
			// some random variance on signs
			this.animation.add("idle", checkpointId == -1 ? [FlxG.random.int(0, 1)] : [2], 1);
			this.animation.play("idle");
			this.setFacingFlip(LEFT, true, false);
			this.setFacingFlip(RIGHT, false, false);
			this.facing = Math.random() < 0.5 ? LEFT : RIGHT;
		}
		else
		{
			this.visible = false;
		}
		this.exists = true;
	}
}

class TriggerType
{
	public static final DIALOG:Int = 0;
	public static final MOVE_LEVEL:Int = 1;
}
