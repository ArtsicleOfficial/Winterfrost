package tiles;

class TilePosition
{
	public var x:Int;
	public var y:Int;

	public var searched:Bool;

	public function new(x:Int = 0, y:Int = 0, searched:Bool = false)
	{
		this.x = x;
		this.y = y;
		this.searched = searched;
	}

	public function squaredDistanceTo(tilePos:TilePosition):Int
	{
		return ((this.x - tilePos.x) * (this.x - tilePos.x)) + ((this.y - tilePos.y) * (this.y - tilePos.y));
	}

	public function distanceTo(tilePos:TilePosition):Float
	{
		return Math.sqrt(squaredDistanceTo(tilePos));
	}

	public function setPosition(x:Int = 0, y:Int = 0)
	{
		this.x = x;
		this.y = y;
	}

	public function setPositionTilePos(tilePos:TilePosition)
	{
		this.x = tilePos.x;
		this.y = tilePos.y;
	}

	public function equals(tilePos:TilePosition):Bool
	{
		return tilePos.x == x && tilePos.y == y;
	}
}
