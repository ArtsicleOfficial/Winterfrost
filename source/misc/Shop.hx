package misc;

import openfl.geom.Rectangle;

class Shop
{
	public var item1:UpgradeType;
	public var item2:UpgradeType;

	public var area:Rectangle;

	public var id:Int;

	public var shopkeeper:Shopkeeper;

	public function new(area:Rectangle, item1:UpgradeType = null, item2:UpgradeType = null, id:Int)
	{
		this.area = area;
		this.item1 = item1;
		this.item2 = item2;
		this.id = id;
	}
}
