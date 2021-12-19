package tiles;

import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;

class ParallaxBG extends FlxTypedGroup<FlxSprite>
{
	public final PARALLAX_SCROLLER_FACTORS:Array<Float> = [0.1, 0.2];
	public final PARALLAX_SCROLLERS_COLORS:Array<Int> = [0xFF1B2F58, 0xFF16274B];

	var foreground = new Array<FlxSprite>();
	var background = new Array<FlxSprite>();

	public function new()
	{
		super();
	}

	public function populate(amt:Int = 10, minX:Int = 0, maxX:Int = 500, minWidth:Int = 50, maxWidth:Int = 100, minY:Int = 20, maxY:Int = 100,
			height:Int = 1000)
	{
		for (i in 0...amt)
		{
			var spr = new FlxSprite(Math.random() * (maxX - minX) + minX, Math.random() * (maxY - minY) + minY);
			var dist = Math.floor(Math.random() * PARALLAX_SCROLLER_FACTORS.length);
			spr.makeGraphic(cast Math.round(Math.random() * (maxWidth - minWidth)) + minWidth, height, PARALLAX_SCROLLERS_COLORS[dist]);
			spr.scrollFactor.set(PARALLAX_SCROLLER_FACTORS[dist], PARALLAX_SCROLLER_FACTORS[dist]);
			if (dist == 1)
			{
				background.push(spr);
			}
			else
			{
				foreground.push(spr);
			}
		}
		for (i in background)
		{
			add(i);
		}
		for (i in foreground)
		{
			add(i);
		}
	}
}
