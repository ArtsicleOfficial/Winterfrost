package misc;

import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class AimCircle extends FlxSprite
{
	private var circleActive:Bool;

	public var tileX:Int;
	public var tileY:Int;

	public var importantTweening = false;

	public function new(circleActive:Bool = false, tileX:Int = 0, tileY:Int = 0, tileWidth:Int = 0)
	{
		super(tileX * tileWidth, tileY * tileWidth);
		this.tileX = tileX;
		this.tileY = tileY;
		loadGraphic("assets/images/aimCircles.png", true, 24, 24);
		animation.add("active", [0, 1, 2, 1], 3);
		animation.add("unactive", [3, 4], 1);
		animation.add("x", [5], 1);
		animation.play("unactive", true, false, 0);
		setCircleActive(circleActive);
	}

	public function positionCircle(tileX:Int, tileY:Int, tileWidth:Int)
	{
		this.tileX = tileX;
		this.tileY = tileY;
		this.setPosition(tileX * tileWidth, tileY * tileWidth);
	}

	public function setCircleActive(circleActive:Bool, playEffect:Bool = true, setFrame:Int = 0)
	{
		// todo: play effect
		this.circleActive = circleActive;
		if (circleActive)
		{
			animation.play("active", true, false, setFrame);
		}
		else
		{
			animation.play("unactive", true, false, setFrame);
		}
	}

	public function setCircleX()
	{
		animation.play("x");
	}

	public function bumpTween()
	{
		if (importantTweening)
		{
			return;
		}
		FlxTween.tween(this.scale, {x: 1.04, y: 1.04}, 0.02, {
			ease: FlxEase.quadOut,
			onComplete: function(_)
			{
				FlxTween.tween(this.scale, {x: 1, y: 1}, 0.1, {
					ease: FlxEase.quadIn,
					onComplete: function(_) {}
				});
			}
		});
	}

	public function fadeInTween(duration:Float, ?completed:Void->Void = null)
	{
		// FlxTween.cancelTweensOf(this);
		importantTweening = true;
		this.scale.set(0, 0);
		FlxTween.tween(this.scale, {x: 1, y: 1}, duration, {
			ease: FlxEase.bounceIn,
			onComplete: function(_)
			{
				importantTweening = false;
				if (completed != null)
				{
					completed();
				}
			}
		});
		this.alpha = 0;
		FlxTween.tween(this, {alpha: 1}, duration, {
			ease: FlxEase.quintIn
		});
	}

	public function fadeOutTween(duration:Float, ?completed:Void->Void = null)
	{
		// FlxTween.cancelTweensOf(this);
		importantTweening = true;
		this.scale.set(1, 1);
		FlxTween.tween(this.scale, {x: 0, y: 0}, duration, {
			ease: FlxEase.quintIn,
			onComplete: function(_)
			{
				importantTweening = false;
				if (completed != null)
				{
					completed();
					kill();
				}
			}
		});
		this.alpha = 1;
		FlxTween.tween(this, {alpha: 0}, duration, {
			ease: FlxEase.quintIn
		});
	}
}
