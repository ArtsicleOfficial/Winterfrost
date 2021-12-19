package game;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.input.actions.FlxAction.FlxActionDigital;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;

class Titlescreen extends FlxState
{
	var next:FlxActionDigital;

	override public function create()
	{
		next = new FlxActionDigital();
		next.addKey(Z, JUST_PRESSED);
		next.addGamepad(A, JUST_PRESSED);

		FlxG.camera.fade(null, 1, true);
		var bg = new FlxSprite(0, 0);
		bg.scrollFactor.set(0, 0);
		bg.loadGraphic("assets/images/cabinAnimated.png", true, 320, 240);
		bg.animation.add("idle", [0, 1, 2, 1], 4);
		bg.animation.play("idle");
		add(bg);

		var bgRect = new FlxSprite(0, 20);
		bgRect.makeGraphic(FlxG.width, 50, new FlxColor(0xFF36240c));
		add(bgRect);
		bgRect.alpha = 0;
		FlxTween.tween(bgRect, {alpha: 0.85}, 2, {ease: FlxEase.quintInOut});

		var logo = new FlxSprite(0, 0);
		logo.loadGraphic("assets/images/logo.png");
		logo.screenCenter(FlxAxes.XY);
		logo.y -= 75;
		logo.scrollFactor.set(0, 0);
		//-100 for offscreen
		logo.y -= 200;
		var zToPlay = new FlxText(0, 0, 200, "[Z] to Start", 16);
		zToPlay.screenCenter(FlxAxes.XY);
		zToPlay.y += 30;
		zToPlay.x -= 20;
		zToPlay.x -= 200;
		FlxTween.tween(logo, {y: logo.y + 200}, 2.5, {
			ease: FlxEase.quadOut,
			onComplete: function(_)
			{
				FlxTween.tween(zToPlay, {x: zToPlay.x + 200}, 1.5, {ease: FlxEase.quadOut});
			}
		});
		zToPlay.setFormat(null, 16, 0xFF4690be, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF4d2c0e);
		add(zToPlay);
		add(logo);

		if (FlxG.sound.music == null)
		{
			FlxG.sound.playMusic("assets/music/song.mp3", 0.35, true);
		}

		super.create();
	}

	var going = false;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (next.check() && !going)
		{
			FlxG.camera.fade(null, 1, false, function()
			{
				FlxG.switchState(new PlayState());
			}, true);
			going = true;
		}
	}
}
