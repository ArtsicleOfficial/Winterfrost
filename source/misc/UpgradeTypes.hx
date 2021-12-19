package misc;

class UpgradeTypes
{
	public static final MELT_SOLID = new UpgradeType("assets/images/solidUpgrade.png", "Melt Solid Tiles");
	public static final BREAK_TILES = new UpgradeType("assets/images/breakUpgrade.png", "Break Tiles");
	public static final SPEED = new UpgradeType("assets/images/speedUpgrade.png", "Speed");
	public static final RANGE = new UpgradeType("assets/images/rangeUpgrade.png", "Range");
	public static final SOLD = new UpgradeType("assets/images/soldUpgrade.png", "SOLD OUT");

	public static final ALL_TYPES = [MELT_SOLID, BREAK_TILES, SPEED, RANGE, SOLD];

	public static function getByName(name:String)
	{
		for (i in ALL_TYPES)
		{
			if (i.name == name)
			{
				return i;
			}
		}
		return null;
	}
}
