package tiles;

import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class FallingTile extends FlxSprite
{
	var tileSize:Int;

	public var tileID:Int;

	public var fallDistance:Int;

	public var tileX:Int;
	public var tileY:Int;

	public function new(tileX:Int, tileY:Int, tileSize:Int, tileID:Int, collidable:Bool = true)
	{
		this.tileSize = tileSize;
		this.tileID = tileID;
		super(tileX * tileSize, tileY * tileSize);
		loadGraphic("assets/images/tiles.png", true, 24, 24);
		/*animation.add("idle", [tileID], 1, false);
			animation.play("idle"); */
		animation.frameIndex = tileID;
		this.fallDistance = 0;
		this.tileX = tileX;
		this.tileY = tileY;
		this.immovable = true;
		this.allowCollisions = collidable ? ANY : NONE;
	}

	public function tweenDownOneTile()
	{
		FlxTween.completeTweensOf(this);
		fallDistance++;
		this.tileY++;
		FlxTween.tween(this, {y: y + tileSize}, 0.2, {
			ease: fallDistance == 1 ? FlxEase.quadIn : FlxEase.linear
		});
	}
}
