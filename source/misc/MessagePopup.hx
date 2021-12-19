package misc;

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import js.html.webgl.Sampler;

class MessagePopup extends FlxText
{
	var fadeSpeed:Float;

	public function new(x:Float, y:Float, text:String, fadeSpeed:Float = 1)
	{
		super(x, y, 160, text);
		this.alpha = 0;
		this.fadeSpeed = fadeSpeed;
		setFormat(null, 8, null, CENTER, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
	}

	public function fadeInOut(?changeText:String = null, ?tempFadeSpeed:Float = null)
	{
		if (changeText != null)
		{
			set_text(changeText);
		}
		var fade = this.fadeSpeed;
		if (tempFadeSpeed != null)
		{
			fade = tempFadeSpeed;
		}
		this.alpha = 0;
		FlxTween.cancelTweensOf(this);
		FlxTween.tween(this, {alpha: 1}, fade, {
			ease: FlxEase.quintOut,
			onComplete: function(_)
			{
				FlxTween.tween(this, {alpha: 1}, fade, {
					onComplete: function(_)
					{
						FlxTween.tween(this, {alpha: 0}, fade, {ease: FlxEase.quintIn});
					}
				});
			}
		});
	}

	public function fadeOut(?tempFadeSpeed:Float = null)
	{
		FlxTween.cancelTweensOf(this);
		FlxTween.tween(this, {alpha: 0}, tempFadeSpeed, {ease: FlxEase.quintIn});
	}

	public function fadeIn(?changeText:String = null, ?tempFadeSpeed:Float = null)
	{
		if (changeText != null)
		{
			set_text(changeText);
		}
		var fade = this.fadeSpeed;
		if (tempFadeSpeed != null)
		{
			fade = tempFadeSpeed;
		}
		this.alpha = 0;
		FlxTween.cancelTweensOf(this);
		FlxTween.tween(this, {alpha: 1}, fade, {
			ease: FlxEase.quintOut
		});
	}
}
