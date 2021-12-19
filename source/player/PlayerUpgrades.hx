package player;

import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import misc.UpgradeType;
import misc.UpgradeTypes;

class PlayerUpgrades
{
	public inline static final MAX_RANGE:Float = 2;
	public inline static final DEFAULT_RANGE:Float = 1;
	public inline static final RANGE_STEP:Float = 0.5;
	public inline static final MAX_LIGHTSPEED:Float = 0;
	public inline static final DEFAULT_LIGHTSPEED:Float = 2;
	public inline static final LIGHTSPEED_STEP:Float = -0.5;

	public inline static final CANLIGHTSOLIDTILES_COST:Int = 500;
	public inline static final DESTROYONLIGHT_COST:Int = 250;

	public var money:Int;

	public var range:Upgrade<Float>;
	public var lightSpeed:Upgrade<Float>;
	public var canLightSolidTiles:Upgrade<Bool>;
	public var destroyOnLight:Upgrade<Bool>;

	public function new(range:Float = DEFAULT_RANGE, lightSpeed:Float = 2, canLightSolidTiles:Bool = false, destroyOnLight:Bool = false, money:Int = 0)
	{
		this.range = new Upgrade<Float>(UpgradeTypes.RANGE, range, "Lighter Range", RANGE_STEP, MAX_RANGE, null, function(range):Int
		{
			return cast 3 * Math.ceil((range + 1) * (range + 1) * (range + 1) * (range + 1) * Math.PI);
		});

		this.lightSpeed = new Upgrade<Float>(UpgradeTypes.SPEED, lightSpeed, "Lighter Speed", LIGHTSPEED_STEP, MAX_LIGHTSPEED, null, function(lightSpeed):Int
		{
			var twoMinus = 2 - lightSpeed + 1.5;
			return cast Math.ceil(twoMinus * twoMinus * twoMinus * twoMinus);
		});

		this.canLightSolidTiles = new Upgrade<Bool>(UpgradeTypes.MELT_SOLID, canLightSolidTiles, "Destroy Foreground Tiles", true, true,
			CANLIGHTSOLIDTILES_COST, null);
		this.destroyOnLight = new Upgrade<Bool>(UpgradeTypes.BREAK_TILES, destroyOnLight, "Destroy Background Tiles", true, true, DESTROYONLIGHT_COST, null);

		this.money = money;
	}
}
