package tiles;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.tile.FlxTilemap;
import flixel.util.FlxDirectionFlags;
import misc.PhysicsOutput;

class WinterTilemap
{
	// Each tile is either falling or it isn't.
	// Falling ones are moved down every physics step and their index in this array is respectively updated.
	// If a falling one hits a regular one, it shatters the regular
	public var fallingTiles:Array<FallingTile>;

	public var tilemap:FlxTilemap;
	public var ladderTiles:FlxTilemap;
	public var decorTiles:FlxTilemap;

	public static inline final FALLING_BREAK_CHANCE:Float = 1;

	public function new(tilemap:FlxTilemap, ladderTiles:FlxTilemap, decorTiles:FlxTilemap)
	{
		this.tilemap = tilemap;
		this.fallingTiles = new Array<FallingTile>();
		this.ladderTiles = ladderTiles;
		this.decorTiles = decorTiles;
		for (i in 0...tilemap.widthInTiles * tilemap.heightInTiles)
		{
			fallingTiles[i] = null;
		}
	}

	// Does a physics step and returns the number of tiles destroyed for money
	public function physicsStep():PhysicsOutput
	{
		var numTilesBroken = 0;
		var newFallingTiles = new Array<FallingTile>();
		// Create a buffer array and loop through each tile in the map
		var buffer:Array<Int> = tilemap.getData().copy();
		// Set all unsupported tiles to falling ones
		var i = tilemap.heightInTiles - 1;
		while (i >= 0)
		{
			for (j in 0...tilemap.widthInTiles)
			{
				var pos = getTilesIndex(j, i);
				var tile = buffer[pos];

				if (!isTilePhysics(tile) || isTileFalling(pos) || isTileConnectedToFoundationAtAnyPoint(j, i, buffer))
				{
					continue;
				}

				// If not sturdy, it doesn't have something below it, so let's make it fall! And add some screenshake while we're at it... and particle FX later.
				newFallingTiles.push(setTileFalling(pos));
			}
			i--;
		}

		// Look through falling tiles and make them fall!
		var i = tilemap.heightInTiles - 1;
		while (i >= 0)
		{
			for (j in 0...tilemap.widthInTiles)
			{
				var pos = getTilesIndex(j, i);
				var tile = buffer[pos];

				// Whether this tile is not falling... or if it is falling but will hit the bottom of the map
				if (!isTileFalling(pos) || i + 1 >= tilemap.heightInTiles)
				{
					continue;
				}

				var targetPos = getTilesIndex(j, i + 1);
				var targetTile = tilemap.getData()[targetPos];

				// If this tile is air then just swap the tiles
				// If the target is a background physics tile and the falling tile is a foreground physics tile, destroy the background
				if (!isTileSolid(targetTile) || (isTileBackgroundPhysics(targetTile)))
				{
					/*fallingTiles[targetPos] = fallingTiles;
						fallingTiles[pos] = 0; */
					/*if (isTileBackgroundPhysics(targetTile))
						{
							tilemap.setTileByIndex(pos, 0);
							numTilesBroken++;
						}
						else
						{
							tilemap.setTileByIndex(pos, targetTile);
						}
						tilemap.setTileByIndex(targetPos, tile); */
					fallingTiles[pos].tweenDownOneTile();
					fallingTiles[targetPos] = fallingTiles[pos];
					fallingTiles[pos] = null;
					if (isTileBackgroundPhysics(tilemap.getTileByIndex(targetPos)))
					{
						numTilesBroken++;
					}
					tilemap.setTileByIndex(targetPos, 0);
				}
				// The tile this falling tile will hit is solid
				else
				{
					tilemap.setTileByIndex(pos, fallingTiles[pos].tileID);
					// Tile must fall a distance to break/be broken
					if (fallingTiles[pos] != null && fallingTiles[pos].fallDistance > 1)
					{
						breakTile(pos);
						numTilesBroken++;
						if (isTilePhysics(targetTile))
						{
							// 100% chance the tile it hits get broken
							breakTile(targetPos);
							numTilesBroken++;
						}
					}
					setFallingTileStill(pos);
				}
			}
			i--;
		}
		return new PhysicsOutput(numTilesBroken, newFallingTiles);
	}

	public inline function getTileSize():Int
	{
		return cast(tilemap.width / tilemap.widthInTiles, Int);
	}

	public function setTileFalling(pos:Int):FallingTile
	{
		var x:Int = cast Math.round((pos / tilemap.widthInTiles - Math.floor(pos / tilemap.widthInTiles)) * tilemap.widthInTiles);
		var y:Int = cast Math.floor(pos / tilemap.widthInTiles);
		if ((isTileForegroundPhysics(tilemap.getTile(x, y + 1))
			|| isTileGround(tilemap.getTile(x, y + 1))
			|| isTileForegroundShop(tilemap.getTile(x, y + 1)))
			|| (isTileBackgroundPhysics(tilemap.getTileByIndex(pos)) && isTileBackgroundPhysics(tilemap.getTile(x, y + 1))))
		{
			return null;
		}
		fallingTiles[pos] = new FallingTile(x, y, getTileSize(), tilemap.getTileByIndex(pos), isTileForegroundPhysics(tilemap.getTileByIndex(pos)));
		tilemap.setTileByIndex(pos, 0);
		// todo particle fx?
		FlxG.camera.shake(0.01, 0.1, null, false);
		return fallingTiles[pos];
	}

	inline public function isTileFalling(pos:Int):Bool
	{
		return fallingTiles[pos] != null;
	}

	public function breakTile(pos:Int)
	{
		tilemap.setTileByIndex(pos, 0);
		setFallingTileStill(pos);
		FlxG.sound.play("assets/sounds/break.mp3", 1, false);
		FlxG.camera.shake(0.01, 0.02, null, false);
	}

	// Loosen a tile by melting it
	public function meltTile(pos:Int):FallingTile
	{
		return setTileFalling(pos);
		// FlxG.camera.shake(0.00001, 0.01, null, false);
	}

	// Destroy a tile by bursting it into flames
	public function incinerateTile(pos:Int)
	{
		tilemap.setTileByIndex(pos, 0);
		setFallingTileStill(pos);
		FlxG.camera.shake(0.001, 0.04, null, false);
	}

	public function setFallingTileStill(pos:Int)
	{
		fallingTiles[pos] = null;
	}

	inline public function getTilesIndex(x:Int, y:Int):Int
	{
		return y * tilemap.widthInTiles + x;
	}

	// Whether a tile can hold up others to prevent them from falling
	inline public function isTileSolid(tileId:Int):Bool
	{
		return (tileId >= 3 && tileId <= 38);
	}

	// Whether or not a tile falls when not supported (the bright blue icy ones)
	inline public function isTilePhysics(tileId:Int):Bool
	{
		return (tileId >= 12 && tileId <= 29);
	}

	// Whether or not a tile is collidable
	inline public function isTileCollidable(tileId:Int):Bool
	{
		return tilemap.getTileCollisions(tileId) != FlxDirectionFlags.NONE;
	}

	inline public function isTileForegroundPhysics(tileId:Int):Bool
	{
		return (tileId >= 12 && tileId <= 20);
	}

	inline public function isTileBackgroundPhysics(tileId:Int):Bool
	{
		return (tileId >= 21 && tileId <= 29);
	}

	inline public function isTileForegroundShop(tileId:Int):Bool
	{
		return (tileId >= 30 && tileId <= 39);
	}

	inline public function isTileBackgroundShop(tileId:Int):Bool
	{
		return (tileId >= 40 && tileId <= 48);
	}

	inline public function isTileGround(tileId:Int):Bool
	{
		return tileId >= 3 && tileId <= 11;
	}

	inline public function isTileFoundation(tileId:Int):Bool
	{
		return !isTilePhysics(tileId) && isTileSolid(tileId);
	}

	public function tileAtIsFoundation(x:Int, y:Int):Bool
	{
		if (x < 0)
		{
			return true;
		}
		else if (y < 0)
		{
			return true;
		}
		else if (x >= tilemap.widthInTiles)
		{
			return true;
		}
		else if (y >= tilemap.heightInTiles)
		{
			return true;
		}
		return isTileFoundation(tilemap.getTile(x, y));
	}

	public function tileAtIsFoundationAndSurroundedByNNeighbors(x:Int, y:Int, n:Int):Bool
	{
		var neighborCount:Int = 0;
		if (isTileFoundation(tilemap.getTile(x - 1, y)))
			neighborCount++;
		if (isTileFoundation(tilemap.getTile(x + 1, y)))
			neighborCount++;
		if (isTileFoundation(tilemap.getTile(x, y - 1)))
			neighborCount++;
		if (isTileFoundation(tilemap.getTile(x, y + 1)))
			neighborCount++;
		return isTileFoundation(tilemap.getTile(x, y)) && neighborCount >= n;
	}

	public function isTileConnectedToFoundationAtAnyPoint(x:Int, y:Int, buffer:Array<Int>):Bool
	{
		var search = new Array<TilePosition>();
		search.push(new TilePosition(x, y, false));
		var searchedAll:Bool = false;
		while (!searchedAll)
		{
			searchedAll = true;

			for (obj in 0...search.length)
			{
				var i = search[obj];
				if (!i.searched)
				{
					if (isTileFoundation(buffer[getTilesIndex(i.x, i.y)]))
					{
						return true;
					}
					search = search.concat(getConnectedSolidTiles(i.x, i.y, search, buffer));
					i.searched = true;
					searchedAll = false;
				}
			}
		}
		return false;
	}

	public function getConnectedSolidTiles(x:Int, y:Int, dupes:Array<TilePosition>, buffer:Array<Int>):Array<TilePosition>
	{
		var array:Array<TilePosition> = new Array<TilePosition>();
		for (i in cast(Math.max(y - 1, 0), Int)...cast(Math.min(y + 2, tilemap.heightInTiles), Int))
		{
			for (j in cast(Math.max(x - 1, 0), Int)...cast(Math.min(x + 2, tilemap.widthInTiles), Int))
			{
				if (!(j == x || y == i))
					continue;
				if ((j == x && y == i) || !isTileSolid(buffer[getTilesIndex(j, i)]))
					continue;
				var foundDupe:Bool = false;
				for (o in dupes)
					if (o.x == j && o.y == i)
						foundDupe = true;
				if (foundDupe)
					continue;
				array.push(new TilePosition(j, i));
			}
		}
		return array;
	}
}
