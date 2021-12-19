package;

import flixel.FlxG;
import flixel.FlxGame;
import game.EndGame;
import game.PlayState;
import game.Titlescreen;
import game.UpgradesState;
import misc.GrainFilter;
import openfl.display.Sprite;
import player.Upgrade;

/*
 * Get this list of To:Do done!!!
 * Due: Dec 19th
 * 
 * Levels
 * Saving
 * Add something for player getting stuck in the level (maybe an ability like double jump or level design or hold "R" to restart)
 * Vignette
 */
class Main extends Sprite
{
	public static var grain:GrainFilter;
	public static final saveName:String = "HaxeWinterJamDestroyThings";

	public function new()
	{
		super();
		addChild(new FlxGame(320, 240, Titlescreen, 4));
		FlxG.fixedTimestep = false;
		grain = GrainFilter.create();
		FlxG.game.setFilters([grain]);
	}
}
