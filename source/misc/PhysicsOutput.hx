package misc;

import tiles.FallingTile;

class PhysicsOutput
{
	public var numberTilesBroken:Int;
	public var fallingTilesToAdd:Array<FallingTile>;

	public function new(numberTilesBroken:Int = 0, fallingTilesToAdd:Array<FallingTile>)
	{
		this.numberTilesBroken = numberTilesBroken;
		this.fallingTilesToAdd = fallingTilesToAdd;
	}
}
