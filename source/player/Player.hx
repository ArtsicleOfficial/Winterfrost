package player;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.input.actions.FlxAction.FlxActionDigital;
import flixel.input.actions.FlxActionManager;
import flixel.input.gamepad.id.XInputID;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import haxe.macro.Expr.Function;
import openfl.utils.IAssetCache;
import tiles.TilePosition;

class Player extends FlxSprite
{
	static inline var gravity:Float = 350;
	static inline var speedX:Float = 12;
	static inline var LADDER_SPEED:Float = 64;
	static inline var TIME_TO_LOOK:Float = 0.25;

	// How much to shrink the player's hitbox in width
	static inline var SHRINK_HITBOX:Int = 8;

	public var upgrades:PlayerUpgrades;

	// Tile the player aimed at while firing and will, once firingTimer hits timeToFire, ignite.
	public var aimedTile:TilePosition;

	public var left:FlxActionDigital;
	public var right:FlxActionDigital;
	public var up:FlxActionDigital;
	public var down:FlxActionDigital;

	public var lookUp:FlxActionDigital;
	public var lookDown:FlxActionDigital;

	public var aimLeft:FlxActionDigital;
	public var aimRight:FlxActionDigital;
	public var aimUp:FlxActionDigital;
	public var aimDown:FlxActionDigital;

	public var fire:FlxActionDigital;
	public var cancelFire:FlxActionDigital;

	public var restart:FlxActionDigital;

	public var climbingLadder:Bool;
	public var aiming:Bool;
	public var firingTimer:Float;
	public var fireCooldown:Bool;

	public var quitting = false;

	public var lookingDown = false;
	public var lookingUp = false;

	var lookingDownTimer:Float = 0;
	var lookingUpTimer:Float = 0;

	public function new(x:Float = 0, y:Float = 0, upgrades:PlayerUpgrades = null)
	{
		super(x, y);

		loadGraphic("assets/images/player.png", true, 24, 36, false);
		animation.add("idle", [1, 2], 2);
		animation.add("run", [4, 5, 6, 7, 8, 9, 10, 11], 8);
		animation.add("climb", [14, 16, 15, 14, 12, 13], 6);
		animation.add("climbTransition", [18], 6, false);
		animation.add("slide", [17], 1);
		animation.add("falling", [19, 20], 6);
		animation.add("light", [21], 1);
		animation.play("idle");
		this.width -= SHRINK_HITBOX;
		this.offset.add(SHRINK_HITBOX / 2, 0);

		setFacingFlip(LEFT, true, false);
		setFacingFlip(RIGHT, false, false);

		loadInputs();

		this.drag.x = 300;
		this.drag.y = 20;
		this.maxVelocity.set(80, 250);
		this.climbingLadder = false;
		this.aiming = false;
		this.aimedTile = new TilePosition(0, 0);
		this.allowCollisions = ANY;
		this.firingTimer = 0;
		if (upgrades == null)
		{
			this.upgrades = new PlayerUpgrades();
		}
		else
		{
			this.upgrades = upgrades;
		}
	}

	override public function update(elapsed:Float)
	{
		if (quitting)
		{
			playAnimation("idle");
			return;
		}
		updateMovement(elapsed);
		super.update(elapsed);
	}

	function loadInputs()
	{
		left = new FlxActionDigital();
		left.addKey(LEFT, PRESSED);
		left.addGamepad(LEFT_STICK_DIGITAL_LEFT, PRESSED);
		left.addGamepad(DPAD_LEFT, PRESSED);

		right = new FlxActionDigital();
		right.addKey(RIGHT, PRESSED);
		right.addGamepad(LEFT_STICK_DIGITAL_RIGHT, PRESSED);
		right.addGamepad(DPAD_RIGHT, PRESSED);

		up = new FlxActionDigital();
		up.addKey(UP, PRESSED);
		up.addGamepad(A, PRESSED);
		up.addGamepad(DPAD_UP, PRESSED);
		up.addGamepad(LEFT_STICK_DIGITAL_UP, PRESSED);

		down = new FlxActionDigital();
		down.addKey(DOWN, PRESSED);
		down.addGamepad(LEFT_STICK_DIGITAL_DOWN, PRESSED);
		down.addGamepad(DPAD_DOWN, PRESSED);

		lookUp = new FlxActionDigital();
		lookUp.addKey(A, PRESSED);
		lookUp.addGamepad(RIGHT_STICK_DIGITAL_UP, PRESSED);

		lookDown = new FlxActionDigital();
		lookDown.addKey(S, PRESSED);
		lookDown.addGamepad(RIGHT_STICK_DIGITAL_DOWN, PRESSED);

		aimLeft = new FlxActionDigital();
		aimLeft.addKey(LEFT, JUST_PRESSED);
		aimLeft.addGamepad(DPAD_LEFT, JUST_PRESSED);
		aimLeft.addGamepad(LEFT_STICK_DIGITAL_LEFT, JUST_PRESSED);

		aimRight = new FlxActionDigital();
		aimRight.addKey(RIGHT, JUST_PRESSED);
		aimRight.addGamepad(DPAD_RIGHT, JUST_PRESSED);
		aimRight.addGamepad(LEFT_STICK_DIGITAL_RIGHT, JUST_PRESSED);

		aimUp = new FlxActionDigital();
		aimUp.addKey(UP, JUST_PRESSED);
		aimUp.addGamepad(DPAD_UP, JUST_PRESSED);
		aimUp.addGamepad(LEFT_STICK_DIGITAL_UP, JUST_PRESSED);
		aimUp.addGamepad(A, JUST_PRESSED);

		aimDown = new FlxActionDigital();
		aimDown.addKey(DOWN, JUST_PRESSED);
		aimDown.addGamepad(DPAD_DOWN, JUST_PRESSED);
		aimDown.addGamepad(LEFT_STICK_DIGITAL_DOWN, JUST_PRESSED);

		fire = new FlxActionDigital();
		fire.addKey(Z, JUST_PRESSED);
		fire.addGamepad(X, JUST_PRESSED);

		cancelFire = new FlxActionDigital();
		cancelFire.addKey(X, JUST_PRESSED);
		cancelFire.addGamepad(B, JUST_PRESSED);

		restart = new FlxActionDigital();
		restart.addKey(R, JUST_PRESSED);
		restart.addGamepad(Y, JUST_PRESSED);
	}

	public function getTilePosFeet(tileWidth:Int):TilePosition
	{
		return new TilePosition(Math.round((this.x - this.width / 4) / tileWidth), Math.round((this.y + (this.height / 2)) / tileWidth));
	}

	public function getTilePosCenter(tileWidth:Int):TilePosition
	{
		return new TilePosition(Math.round((this.x - (this.width / 4)) / tileWidth), Math.round((this.y + (this.height / 2)) / tileWidth));
	}

	public function updateLadderMovement(ladderMap:FlxTilemap)
	{
		if (busyFiring())
		{
			return;
		}
		var tileWidth:Int = cast Math.round(ladderMap.width / ladderMap.widthInTiles);
		var playerTilePos = getTilePosFeet(tileWidth);
		var playerLadderTile = ladderMap.getTile(playerTilePos.x, playerTilePos.y);
		if (!climbingLadder)
		{
			if (((up.check() && playerLadderTile == 1) || (down.check() && playerLadderTile == 2)) && FlxG.overlap(this, ladderMap))
			{
				climbingLadder = true;
				FlxTween.tween(this, {x: playerTilePos.x * tileWidth + this.offset.x}, 0.2, {ease: FlxEase.quadInOut});
			}
			return;
		}
		if (playerLadderTile == 0)
		{
			climbingLadder = false;
			return;
		}
		this.velocity.y = 0;
		this.acceleration.y = 0;
		if (up.check())
		{
			this.velocity.y -= LADDER_SPEED;
			// Ladder Top Tile
			if (playerLadderTile == 2)
			{
				climbingLadder = false;
				// Adds a bit of pop-out from the ladder
				// this.velocity.y -= LADDER_SPEED;
			}
		}
		if (down.check())
		{
			this.velocity.y += LADDER_SPEED;
		}
	}

	public inline function busyFiring()
	{
		return this.aiming || this.firingTimer > 0 || this.fireCooldown;
	}

	public function playAnimation(name:String, startFrame:Int = 0)
	{
		if (name == "climb")
		{
			if (animation.name != "climb" && animation.name != "climbTransition")
			{
				animation.play("climbTransition");
			}
			else if (animation.name == "climbTransition" && animation.finished)
			{
				animation.play(name, false, false, startFrame);
			}
		}
		else if (animation.name == "climb")
		{
			animation.play("climbTransition", true);
		}
		if ((animation.name == "climbTransition" && animation.finished) || animation.name != "climbTransition")
		{
			animation.play(name, false, false, startFrame);
		}
	}

	function updateMovement(elapsed)
	{
		lookingDown = false;
		lookingUp = false;
		animation.paused = false;
		if (busyFiring())
		{
			playAnimation("light");
			return;
		}
		if (climbingLadder)
		{
			if (down.check() && isTouching(FLOOR))
			{
				this.climbingLadder = false;
			}
			else if ((left.check() || right.check()) && !(up.check() || down.check()))
			{
				this.climbingLadder = false;
			}
			else
			{
				/*if (animation.name != "climb" && animation.name != "climbTransition")
					{
						animation.play("climbTransition", false);
					}
					if (animation.name == "climbTransition" && animation.finished)
					{
						animation.play("climb", false, false, 16);
				}*/
				playAnimation("climb", 16);
				if (Math.abs(velocity.y) < 4 && animation.name == "climb")
				{
					animation.paused = true;
				}
			}
			return;
		}
		this.acceleration.y = gravity;
		var pressingLR = false;
		if (left.check())
		{
			this.velocity.x -= speedX;
			facing = LEFT;
			pressingLR = true;
		}
		else if (right.check())
		{
			this.velocity.x += speedX;
			facing = RIGHT;
			pressingLR = true;
		}
		if (aimUp.check() && isTouching(FLOOR) && !lookingUp)
		{
			this.velocity.y -= 140;
		}
		if (lookDown.check())
		{
			lookingUp = false;
			lookingUpTimer += elapsed;
			if (lookingUpTimer >= TIME_TO_LOOK)
			{
				lookingDown = true;
			}
		}
		else if (lookUp.check())
		{
			lookingDown = false;
			lookingUpTimer += elapsed;
			if (lookingUpTimer >= TIME_TO_LOOK)
			{
				lookingUp = true;
			}
		}
		else
		{
			lookingUpTimer = 0;
		}
		if (pressingLR && isTouching(FLOOR))
		{
			// animation.play("run", false, false, 1);
			playAnimation("run", 1);
		}
		else if (isTouching(FLOOR) && Math.abs(this.velocity.x) > 5)
		{
			// animation.play("slide", false, false);
			playAnimation("slide");
		}
		else if (!isTouching(FLOOR))
		{
			// todo: falling
			playAnimation("falling");
			// animation.play("idle");
		}
		else
		{
			playAnimation("idle");
		}
	}
}
