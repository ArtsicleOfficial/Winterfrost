package game;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.editors.ogmo.FlxOgmo3Loader;
import flixel.input.actions.FlxAction;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import player.PlayerUpgrades;

class LevelSummary extends FlxSubState
{
	public var bg:FlxSprite;
	public var rect:FlxSprite;

	public var line1:FlxText;
	public var line2:FlxText;
	public var line3:FlxText;
	public var lineLighters:FlxText;

	public var targetCamera:FlxCamera;

	public var tilesDestroyed:Int;
	public var potentialTilesDestroyed:Int;
	public var currencyGained:Int;
	public var percentage:Float;
	public var nextLevel:String;
	public var nextAction:FlxAction;

	public var upgrades:PlayerUpgrades;

	public var goodToGo:Bool = false;

	public function new(tilesDestroyed:Int, potentialTilesDestroyed:Int, currencyGained:Int, nextLevel:String, nextAction:FlxAction, upgrades:PlayerUpgrades)
	{
		this.tilesDestroyed = tilesDestroyed;
		this.potentialTilesDestroyed = potentialTilesDestroyed;
		this.currencyGained = currencyGained;
		this.percentage = tilesDestroyed / potentialTilesDestroyed;

		this.nextLevel = nextLevel;

		this.nextAction = nextAction;
		this.upgrades = upgrades;

		super();
	}

	override public function create()
	{
		targetCamera = new FlxCamera(0, 0, 320, 240, 4);
		targetCamera.useBgAlphaBlending = true;
		targetCamera.bgColor = 0;
		FlxG.cameras.add(targetCamera, false);
		targetCamera.fade(null, 1, true);

		bg = new FlxSprite(0, 0);
		bg.loadGraphic("assets/images/cabinAnimated.png", true, 320, 240);
		bg.animation.add("idle", [0, 1, 2, 1], 4);
		bg.animation.play("idle");
		add(bg);

		rect = new FlxSprite(0, 50);
		rect.makeGraphic(targetCamera.width, 240 - 100, FlxColor.BLACK);
		rect.alpha = 0.8;
		add(rect);

		nextLevel = new FlxOgmo3Loader("assets/data/tilemaps.ogmo", "assets/data/" + nextLevel).getLevelValue("values").nameText;

		line1 = new FlxText(0, 60, 320, Math.round(percentage * 100) + "% Blocks Destroyed (" + tilesDestroyed + "/" + potentialTilesDestroyed + ")", 16);
		line2 = new FlxText(0, 80, 320, "+" + currencyGained + " Ice Crystals (" + upgrades.money + ")", 16);
		lineLighters = new FlxText(0, 100, 320,
			"Lighter upgrades: \nRange: "
			+ upgrades.range.value
			+ " Blocks\nSpeed: "
			+ upgrades.lightSpeed.value
			+ "s\n"
			+ (upgrades.destroyOnLight.value ? "CAN destroy background blocks\n" : "")
			+ (upgrades.canLightSolidTiles.value ? "CAN destroy foreground blocks" : ""),
			8);
		line3 = new FlxText(0, 150, 320, "Next Up:  " + nextLevel + "  [Z]", 16);

		line1.setFormat(null, 16, 0xFFd0a872, CENTER, FlxTextBorderStyle.SHADOW, 0xFF2c4971);
		line2.setFormat(null, 16, 0xFFd0a872, CENTER, FlxTextBorderStyle.SHADOW, 0xFF2c4971);
		lineLighters.setFormat(null, 8, 0xFFa03c31, CENTER, FlxTextBorderStyle.SHADOW, 0xFF3b3736);
		line3.setFormat(null, 16, 0xFF4690be, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF4d2c0e);

		// FlxTween.tween(line1)

		add(line1);
		add(line2);
		add(lineLighters);
		add(line3);

		forEachOfType(FlxSprite, function(entity)
		{
			entity.camera = targetCamera;
			entity.scrollFactor.set(0, 0);
		}, true);

		super.create();
	}

	var going = false;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (nextAction.check() && !going)
		{
			targetCamera.fade(null, 1, false, function()
			{
				close();
				goodToGo = true;
			}, true);
			going = true;
		}
	}
}
