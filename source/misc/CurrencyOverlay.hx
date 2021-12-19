package misc;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton.FlxTypedButton;

class CurrencyOverlay extends FlxTypedGroup<FlxSprite>
{
	public var icon:FlxSprite;
	public var moneyText:FlxText;

	public var initialX:Float;
	public var initialY:Float;

	public var moneyAmt:Int;

	public function new(x:Float, y:Float, money:Int, isARestartedLevel:Bool = false)
	{
		super();
		this.initialX = x;
		this.initialY = y;
		icon = new FlxSprite(x, y); // 5,60
		icon.loadGraphic(isARestartedLevel ? "assets/images/iceAnimatedDark.png" : "assets/images/iceAnimated.png", true, 32, 32);
		icon.animation.add("idle", [0, 1, 2], 2, true);
		icon.animation.add("glimmer", [
			0, 1, 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 1, 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2
		], 6, true);
		icon.animation.play("glimmer", true, false, -1);

		add(icon);

		moneyAmt = money;
		// moneyText = new FlxText(40, 68, 0, money + "").setFormat(null, 16, 0xFFCC9343, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF775C21, true);
		moneyText = new FlxText(x + 35, y + 8, 0, money + "").setFormat(null, 16, 0xFFD8C56F, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF726219, true);
		add(moneyText);
	}

	public function bump()
	{
		FlxTween.cancelTweensOf(icon);
		icon.y = initialY;
		FlxTween.tween(icon, {y: icon.y - 5}, 0.05, {
			ease: FlxEase.quadOut,
			onComplete: function(_)
			{
				FlxTween.tween(icon, {y: icon.y + 5}, 0.05, {ease: FlxEase.quadIn});
			}
		});
		FlxG.sound.play("assets/sounds/coin.mp3", 1, false);
	}
}
