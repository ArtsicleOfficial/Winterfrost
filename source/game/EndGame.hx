package game;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.input.actions.FlxAction;
import lime.tools.SplashScreen;

class EndGame extends FlxState
{
	var next:FlxActionDigital;

	override public function create()
	{
		FlxG.camera.fade(null, 1, true);
		next = new FlxActionDigital();
		next.addKey(Z, JUST_PRESSED);
		next.addGamepad(A, JUST_PRESSED);

		var spr = new FlxSprite(0, 0, "assets/images/theend.png");
		spr.scrollFactor.set(0, 0);
		add(spr);

		super.create();
	}

	var going = false;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		Main.grain.update();
		if (next.check() && !going)
		{
			FlxG.camera.fade(null, 1, false, function()
			{
				FlxG.switchState(new Titlescreen());
			}, true);
			going = true;
		}
	}
}
