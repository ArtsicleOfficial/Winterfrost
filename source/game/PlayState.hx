package game;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.editors.ogmo.FlxOgmo3Loader;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.GraphicVirtualInput;
import flixel.text.FlxText;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSave;
import flixel.util.FlxTimer;
import js.html.Console;
import misc.AimCircle;
import misc.GrainFilter;
import misc.Light;
import misc.MessagePopup;
import misc.PhysicsOutput;
import misc.Shop;
import misc.Shopkeeper;
import misc.SnowScape;
import misc.UpgradeType;
import misc.UpgradeTypes;
import misc.Utility;
import openfl.geom.Rectangle;
import player.Player;
import player.PlayerUpgrades;
import tiles.FallingTile;
import tiles.ParallaxBG;
import tiles.TilePosition;
import tiles.Trigger;
import tiles.WinterTilemap;

class PlayState extends FlxState
{
	// Per-10-second saving
	public static final SAVE_TIME:Float = 10;

	var saveTimer:Float = 0;

	var gameTiles:WinterTilemap;
	var player:Player;
	var playerMessage:MessagePopup;
	var bgSnowscape:SnowScape;
	var fgSnowscape:SnowScape;
	var hud:PlayHud;

	var light:Light;

	// only for loading on state creation, access Player.hx's upgrades for getting info
	var loadedUpgrades:PlayerUpgrades;
	// also only for loading on state creation
	var levelToLoad:String;

	// For transitioning into the level and saying the name from ogmo
	var levelName:String;

	var physicsStepTimer:Float;

	var aimCircles:FlxTypedGroup<AimCircle>;
	var currentAimCircle:Int;

	var upgradesSubState:UpgradesState;
	var openedUpgradesSubState:Bool;

	var parallaxBG:ParallaxBG;

	var shops:Array<Shop>;
	var levelTriggers = new FlxTypedGroup<Trigger>();

	var lightEntityOverlays = new FlxTypedGroup<Light>();

	var quitting:Bool = false;

	var consideringReset:Float = 0;

	var lightingMap:FlxTilemap;

	var playerCameraFollower:FlxSprite;

	var startingDestroyableTiles:Int = 0;
	var destroyedTiles:Int = 0;
	var currencyGained:Int = 0;

	var isARestartedLevel = false;
	var levelSummary:LevelSummary = null;

	var latestCheckpoint:Int = -1;

	public var fallingTiles:FlxTypedGroup<FallingTile>;

	public var shopkeeperMessages = new FlxTypedGroup<MessagePopup>();

	public static final PHYSICS_CLOCK:Float = 0.2;

	public function new(upgradeInstance:PlayerUpgrades = null, levelToLoad:String = "tutoriallevel.json", restarted:Bool = false, latestCheckpoint:Int = -1)
	{
		this.loadedUpgrades = upgradeInstance;
		this.levelToLoad = levelToLoad;
		this.isARestartedLevel = restarted;

		if (loadedUpgrades == null)
		{
			loadGame();
		}
		if (latestCheckpoint != -1)
		{
			this.latestCheckpoint = latestCheckpoint;
		}

		super();
	}

	override public function create()
	{
		// Old bright bg color; same color as character yuck: FlxG.camera.bgColor = 0xFFA4B8D8;
		// Desatured but better bg color: FlxG.camera.bgColor = 0xFF2A3244;
		FlxG.camera.bgColor = 0xFF132242; // dark & saturated
		FlxG.camera.setSize(FlxG.width, FlxG.height);

		FlxG.camera.fade(null, 1, true);

		physicsStepTimer = 0;

		var wind = Math.random() + 0.5;

		parallaxBG = new ParallaxBG();
		add(parallaxBG);

		bgSnowscape = new SnowScape(50, 0.35, 0xFFBBBBCC, wind);
		add(bgSnowscape);
		loadLevel(levelToLoad);
		teleportPlayerToCheckpoint();

		parallaxBG.populate(100, 0, cast gameTiles.tilemap.width, 50, 200, 0, cast gameTiles.tilemap.height, cast gameTiles.tilemap.height);

		light = new Light(player.x, player.y, 75, 0xFFBB22);
		light.alpha = 0;
		add(light);

		FlxG.camera.scroll.set(player.x - FlxG.width / 2, player.y - FlxG.height / 2);

		fgSnowscape = new SnowScape(100, 1, 0xFFDDDDEE, wind);
		add(fgSnowscape);

		add(lightEntityOverlays);

		aimCircles = new FlxTypedGroup<AimCircle>();
		add(aimCircles);

		playerMessage = new MessagePopup(0, 0, "", 1);
		add(playerMessage);

		var texts = new FlxTypedGroup<FlxText>();
		add(texts);

		hud = new PlayHud(loadedUpgrades == null ? 0 : loadedUpgrades.money, texts,
			new TilePosition(gameTiles.tilemap.widthInTiles, gameTiles.tilemap.heightInTiles), isARestartedLevel);
		add(hud);

		// Scrolly text level intro
		var scrollyText = new FlxText(-200, FlxG.height / 2, 200, levelName, 24);
		scrollyText.y -= scrollyText.height / 2;
		scrollyText.setFormat(null, 24, 0xFF9bc4d5, CENTER, FlxTextBorderStyle.SHADOW, 0xFF714721);
		scrollyText.scrollFactor.set(0, 0);

		var rect = new FlxSprite(0, scrollyText.y - 5);
		rect.scrollFactor.set(0, 0);
		rect.makeGraphic(FlxG.width, cast scrollyText.height + 5, FlxColor.BLACK);
		rect.alpha = 0;

		add(rect);

		add(scrollyText);

		// Animation for level text
		hud.setFadedOut();
		quitting = true;
		/*new FlxTimer().start(2,*/
		FlxG.sound.play("assets/sounds/combust.mp3");
		FlxTween.tween(rect, {alpha: 0.5}, 1.5, {
			ease: FlxEase.quadOut,
			onComplete: function(_)
			{
				FlxG.sound.play("assets/sounds/bells.mp3");
				FlxTween.tween(scrollyText, {x: FlxG.width / 2 - 25 - 100}, 0.5, {
					ease: FlxEase.quadOut,
					onComplete: function(_)
					{
						FlxG.camera.shake(0.005, 0.05);
						FlxTween.tween(scrollyText, {x: FlxG.width / 2 + 25 - 100}, 2.5, {
							ease: FlxEase.linear,
							onComplete: function(_)
							{
								FlxG.camera.shake(0.01, 0.05);
								FlxTween.tween(scrollyText, {x: FlxG.width + 200}, 0.5, {
									ease: FlxEase.quadIn,
									onComplete: function(_)
									{
										scrollyText.kill();
										FlxTween.tween(rect, {alpha: 0}, 0.5, {
											ease: FlxEase.quadIn,
											onComplete: function(_)
											{
												rect.kill();
												hud.fadeIn(0.5);
												quitting = false;
												player.quitting = false;
											}
										});
									}
								});
							}
						});
					}
				});
			}
		});

		add(shopkeeperMessages);

		updateMinimap();

		hud.updateMoney(player.upgrades.money);

		upgradesSubState = new UpgradesState(player.aimLeft, player.aimRight, player.fire, player.cancelFire);
		openedUpgradesSubState = false;

		updateLights(true);

		super.create();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		Main.grain.update();

		if (goToLevel != null && levelSummary != null && levelSummary.goodToGo)
		{
			loadToNewLevelAndSwitchState(goToLevel, false);
			goToLevel = null;
		}
		if (quitting)
		{
			player.quitting = true;
			return;
		}

		if (openedUpgradesSubState)
		{
			hud.updateMoney(upgradesSubState.unlocked.money, null);
			player.upgrades = upgradesSubState.unlocked;
			hud.visible = true;
		}

		updateLevelReset(elapsed);

		var playerShop:Shop = null;

		if (player.aiming)
		{
			player.acceleration.set(0, 0);
			player.velocity.set(0, 0);
		}
		else if (player.firingTimer > 0)
		{
			updatePlayerFiringTimer(elapsed);
		}
		else
		{
			updatePhysics(elapsed);

			player.updateLadderMovement(gameTiles.ladderTiles);

			collidePlayerWithTiles();
			if (!player.climbingLadder)
				FlxG.collide(player, gameTiles.ladderTiles);

			playerShop = updateShop();
		}

		updatePlayerCamera();

		updatePlayerMessagePopup();
		if (playerShop == null)
		{
			updatePlayerAiming();
		}

		updateMinimap();

		updateLights();

		updateSaving(elapsed);

		if (!FlxG.overlap(player, levelTriggers, triggerCollided, null))
		{
			if (playerMessage.text == previousTrigger)
			{
				playerMessage.fadeOut(1);
			}
			previousTrigger = "";
		}
	}

	function teleportPlayerToCheckpoint()
	{
		if (latestCheckpoint >= 0)
		{
			for (i in levelTriggers)
			{
				if (i.checkpointId == latestCheckpoint)
				{
					player.x = i.x;
					player.y = i.y + i.height - player.height;
					playerCameraFollower.setPosition(player.x, player.y);
				}
			}
		}
	}

	public var goToLevel:String = null;

	public function openLevelSummary(nextLevel:String)
	{
		FlxG.camera.fade(null, 1, false, function()
		{
			hud.visible = false;
			goToLevel = nextLevel;
			levelSummary = new LevelSummary(destroyedTiles, startingDestroyableTiles, currencyGained, nextLevel, player.fire, player.upgrades);
			openSubState(levelSummary);
		}, true);
	}

	public static final PLAYER_CAMERA_FOLLOWER_LERP_SPEED:Float = 0.1;

	function updatePlayerCamera()
	{
		var to:FlxPoint;
		if (player.aiming && currentAimCircle != null)
		{
			to = aimCircles.members[currentAimCircle].getPosition();
		}
		else if (player.lookingUp)
		{
			to = player.getPosition().add(0, -FlxG.height / 2 + 20);
		}
		else if (player.lookingDown)
		{
			to = player.getPosition().add(0, FlxG.height / 2 - 20);
		}
		else
		{
			to = player.getPosition();
		}
		to = Utility.lerpPos(playerCameraFollower.getPosition(), to, PLAYER_CAMERA_FOLLOWER_LERP_SPEED);
		playerCameraFollower.setPosition(to.x, to.y);
	}

	function collidePlayerWithTiles()
	{
		var velocityBefore = player.velocity.y;
		FlxG.collide(player, gameTiles.tilemap);
		FlxG.collide(player, fallingTiles);
		if (player.velocity.y - velocityBefore < -10)
		{
			var amt = (velocityBefore - player.velocity.y) / 250 / 4;
			amt *= amt * amt;
			FlxG.camera.shake(amt, 0.25);
		}
	}

	function updateLevelReset(elapsed:Float)
	{
		if (consideringReset > 0)
			consideringReset = Math.max(0, consideringReset - elapsed);
		if (player.restart.check())
		{
			if (consideringReset > 0)
			{
				loadToNewLevelAndSwitchState(levelToLoad, false, latestCheckpoint);
			}
			else
			{
				consideringReset = 2;
				playerMessage.fadeInOut("Are you sure? [R] again to restart!", 2 / 3);
			}
		}
	}

	// data of previous trigger
	var previousTrigger:String = "";

	function triggerCollided(player:Player, trigger:Trigger)
	{
		FlxG.log.add("reach this at least");
		if (trigger.data == previousTrigger)
		{
			return;
		}
		FlxG.log.add("test");
		if (trigger.type == TriggerType.DIALOG)
		{
			FlxG.log.add(trigger.data + "!");
			playerMessage.fadeIn(trigger.data);
			if (trigger.checkpointId >= 0)
			{
				latestCheckpoint = trigger.checkpointId;
				if (saveTimer < SAVE_TIME - 1)
				{
					saveTimer = SAVE_TIME;
				}
			}
		}
		else if (trigger.type == TriggerType.MOVE_LEVEL)
		{
			if (trigger.data == "end")
			{
				quitting = true;
				saveGame();
				FlxG.camera.fade(null, 1, false, function()
				{
					FlxG.switchState(new EndGame());
				}, true);
			}
			else
			{
				openLevelSummary(trigger.data);
			}
		}

		previousTrigger = trigger.data;
	}

	function loadToNewLevelAndSwitchState(levelName:String, restarted:Bool = false, latestCheckpoint:Int = -1)
	{
		quitting = true;
		hud.playHudCamera.fade(null, 1, false);
		FlxG.camera.fade(null, 1, false, function()
		{
			FlxG.switchState(new PlayState(player.upgrades, levelName, restarted, latestCheckpoint));
		}, true);
	}

	function loadGame()
	{
		var save = new FlxSave();
		save.bind(Main.saveName);

		if (save.data.range != null)
		{
			loadedUpgrades = new PlayerUpgrades(save.data.range, save.data.lightSpeed, save.data.canLightSolidTiles, save.data.destroyOnLight,
				save.data.money);
		}
		if (save.data.levelToLoad != null)
		{
			levelToLoad = save.data.levelToLoad;
			latestCheckpoint = save.data.latestCheckpoint;
		}
		save.destroy();
	}

	function saveGame()
	{
		var save = new FlxSave();
		save.bind(Main.saveName);

		save.data.range = player.upgrades.range.value;
		save.data.lightSpeed = player.upgrades.lightSpeed.value;
		save.data.canLightSolidTiles = player.upgrades.canLightSolidTiles.value;
		save.data.destroyOnLight = player.upgrades.destroyOnLight.value;
		save.data.money = player.upgrades.money;
		save.data.levelToLoad = levelToLoad;
		save.data.latestCheckpoint = latestCheckpoint;

		save.close();
	}

	function updateSaving(elapsed:Float)
	{
		saveTimer += elapsed;
		if (saveTimer >= SAVE_TIME)
		{
			saveTimer -= SAVE_TIME;
			saveGame();
		}
	}

	function openStore(upgradesAvailable:Array<UpgradeType>)
	{
		upgradesSubState = new UpgradesState(player.aimLeft, player.aimRight, player.fire, player.cancelFire);
		upgradesSubState.setUpgrades(player.upgrades, upgradesAvailable, true);
		hud.visible = false;
		openSubState(upgradesSubState);
		openedUpgradesSubState = true;
	}

	public var cameraTweening = false;
	public var playerInShopDelta = -1;

	function zoomCameraIn()
	{
		cameraTweening = true;
		FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.initialZoom * 1.25}, 0.5, {
			ease: FlxEase.quadInOut,
			onComplete: function(_)
			{
				cameraTweening = false;
			}
		});
	}

	function zoomCameraOut()
	{
		cameraTweening = true;
		FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.initialZoom}, 0.5, {
			ease: FlxEase.quadInOut,
			onComplete: function(_)
			{
				cameraTweening = false;
			}
		});
	}

	inline function cameraZoomedOut()
	{
		return FlxG.camera.zoom == FlxG.camera.initialZoom;
	}

	inline function cameraZoomedIn()
	{
		return FlxG.camera.zoom == FlxG.camera.initialZoom * 1.25;
	}

	function updateShop()
	{
		var collidingShop = getCollidingShop();
		if (collidingShop == null)
		{
			if (!cameraTweening && cameraZoomedIn() && !player.aiming && playerMessage.text == "[Z]")
			{
				zoomCameraOut();
				playerMessage.fadeOut(0.5);
			}
			if (playerInShopDelta != -1 && getShopByID(playerInShopDelta).shopkeeper.text.alpha == 0)
			{
				var shopWas = playerInShopDelta;
				new FlxTimer().start(0.5, function(_)
				{
					if (getCollidingShop() == null)
					{
						this.getShopByID(shopWas).shopkeeper.say(Shopkeeper.LEAVINGS[FlxG.random.int(0, Shopkeeper.LEAVINGS.length - 1)]);
					}
				});
			}
			playerInShopDelta = -1;
			return null;
		}
		if (playerInShopDelta == -1)
		{
			if (collidingShop.shopkeeper.text.alpha == 0)
			{
				new FlxTimer().start(1, function(_)
				{
					if (getCollidingShop() != null)
					{
						collidingShop.shopkeeper.say(Shopkeeper.GREETINGS[FlxG.random.int(0, Shopkeeper.GREETINGS.length - 1)]);
					}
				});
			}
			playerMessage.fadeIn("[Z]", 0.5);
		}
		if (!cameraTweening && cameraZoomedOut())
		{
			zoomCameraIn();
		}

		if (player.fire.check())
		{
			openStore([collidingShop.item1, collidingShop.item2]);
		}

		playerInShopDelta = collidingShop.id;

		return collidingShop;
	}

	function getCollidingShop()
	{
		for (i in shops)
		{
			if (collision(player.x, player.y, player.width, player.height, i.area.x, i.area.y, i.area.width, i.area.height))
			{
				return i;
			}
		}

		return null;
	}

	function collision(x:Float, y:Float, w:Float, h:Float, x2:Float, y2:Float, w2:Float, h2:Float)
	{
		return (x + w >= x2 && y + h >= y2 && x2 + w2 >= x && y2 + h2 >= y);
	}

	function updateLights(instantTele:Bool = false)
	{
		var speed:Float = instantTele ? 1 : 0.2;
		var to:FlxPoint;
		if (currentAimCircle != null && (player.firingTimer > 0 || player.aiming))
		{
			if (player.firingTimer > 0)
			{
				to = new FlxPoint(aimCircles.members[currentAimCircle].x - gameTiles.getTileSize(),
					aimCircles.members[currentAimCircle].y - gameTiles.getTileSize());
			}
			else
			{
				// Lerped between normal standing and firing on that tile if the player is aiming (so they don't get close enough to burn it)
				to = Utility.lerpPos(new FlxPoint(player.x + ((player.facing == RIGHT) ? (-15) : ((-player.width * 4) + 20)), player.y - player.height / 2),
					new FlxPoint(aimCircles.members[currentAimCircle].x - gameTiles.getTileSize(),
						aimCircles.members[currentAimCircle].y - gameTiles.getTileSize()),
					0.4);
			}
		}
		else
		{
			to = new FlxPoint(player.x + ((player.facing == RIGHT) ? (-15) : ((-player.width * 4) + 20)), player.y - player.height / 2);
		}
		to = Utility.lerpPos(light.getPosition(), to, speed);
		light.position(to.x + (light.size / 2), to.y + (light.size / 2));
		// light.visible = player.busyFiring();
	}

	function updateMinimap()
	{
		hud.updateMinimap(gameTiles, player.x / gameTiles.getTileSize(), player.y / gameTiles.getTileSize());
	}

	var amtToGive:Int = 0;

	function giveMoney(amt:Int)
	{
		if (isARestartedLevel)
		{
			amtToGive += amt % 2;
			amt -= amt % 2;
		}
		if (amtToGive % 2 == 0)
		{
			amt += amtToGive;
			amtToGive = 0;
		}
		amt = cast Math.ceil(amt / 2);
		currencyGained += amt;
		player.upgrades.money += amt;
		hud.updateMoney(player.upgrades.money, player.getPosition());
	}

	function updatePlayerMessagePopup()
	{
		playerMessage.setPosition(player.x - playerMessage.fieldWidth / 2 + player.width / 2, player.y - playerMessage.height);
	}

	function updatePhysics(elapsed:Float):Bool
	{
		physicsStepTimer += elapsed;
		if (physicsStepTimer < PHYSICS_CLOCK)
		{
			return false;
		}
		var physOutput:PhysicsOutput = gameTiles.physicsStep();
		giveMoney(physOutput.numberTilesBroken);
		destroyedTiles += physOutput.numberTilesBroken;
		physicsStepTimer -= PHYSICS_CLOCK;

		for (i in physOutput.fallingTilesToAdd)
		{
			fallingTiles.add(i);
		}
		for (i in fallingTiles.members)
		{
			if (i == null || gameTiles.fallingTiles[gameTiles.getTilesIndex(i.tileX, i.tileY)] == null)
			{
				fallingTiles.remove(i);
			}
		}

		return true;
	}

	function loadEntities(entity:EntityData)
	{
		if (entity.name.toLowerCase() == "player")
		{
			player = new Player(entity.x, entity.y - entity.originY - 2, loadedUpgrades);
			add(player);
			playerCameraFollower = new FlxSprite(player.x, player.y);
			playerCameraFollower.setSize(player.width, player.height);
			playerCameraFollower.visible = false;
			add(playerCameraFollower);
			FlxG.camera.follow(playerCameraFollower, PLATFORMER, 0.8);
			FlxG.camera.deadzone.bottom += player.height;
			FlxG.camera.deadzone.top += player.height;
		}
	}

	function loadTriggers(entity:EntityData)
	{
		if (entity.name == "triggerdialog")
		{
			var trigger:Trigger;
			trigger = new Trigger(entity.x, entity.y, entity.width, entity.height, TriggerType.DIALOG, entity.values.dialog);
			trigger.visible = entity.values.visible;
			trigger.width = entity.width;
			trigger.height = entity.height;
			levelTriggers.add(trigger);
		}
		else if (entity.name == "triggernewlevel")
		{
			levelTriggers.add(new Trigger(entity.x, entity.y, entity.width, entity.height, TriggerType.MOVE_LEVEL, entity.values.levelname));
		}
		else if (entity.name == "triggercheckpoint")
		{
			levelTriggers.add(new Trigger(entity.x, entity.y, entity.width, entity.height, TriggerType.DIALOG, "Checkpoint!", entity.values.uniqueID));
		}
	}

	function loadLightEntities(entity:EntityData)
	{
		var entityLight = new FlxSprite(entity.x, entity.y);
		if (entity.name == "regularLightObject")
		{
			entityLight.loadGraphic(entity.values.path);
		}
		else if (entity.name == "fireplace")
		{
			entityLight.loadGraphic("assets/images/fireplace.png", true, 24, 24);
			entityLight.animation.add("idle", [0, 1, 2], 8);
			entityLight.animation.play("idle");
		}
		add(entityLight);
		var ogmoColor:String = entity.values.colorLight;
		var actualColor:String = "0xFF";
		actualColor += ogmoColor.substr(1, 6);
		var lightObj = new Light(0, 0, entity.values.size, cast actualColor);
		lightObj.position(entity.x + gameTiles.getTileSize() / 2, entity.y + gameTiles.getTileSize() / 2);
		lightEntityOverlays.add(lightObj);
	}

	function loadShopEntities(entity:EntityData)
	{
		shops.push(new Shop(new Rectangle(entity.x, entity.y, entity.width, entity.height), UpgradeTypes.getByName(entity.values.item1),
			UpgradeTypes.getByName(entity.values.item2), entity.values.shopID));
	}

	function loadShopkeeperEntities(entity:EntityData)
	{
		var shopkeeper = new Shopkeeper(entity.x, entity.y, entity.values.shopID, !entity.values.facingLeft);

		getShopByID(shopkeeper.shopID).shopkeeper = shopkeeper;

		add(shopkeeper.keeper);
		shopkeeperMessages.add(shopkeeper.text);
	}

	function getShopByID(id:Int)
	{
		for (i in shops)
		{
			if (i.id == id)
			{
				return i;
			}
		}
		FlxG.log.warn("Shop id " + id + " does not exist!");
		return null;
	}

	function updatePlayerFiringTimer(elapsed:Float)
	{
		player.firingTimer += elapsed;
		if (player.firingTimer >= player.upgrades.lightSpeed.value)
		{
			FlxG.sound.play("assets/sounds/combust.mp3", 1, false);
			bgSnowscape.unpause();
			fgSnowscape.unpause();
			FlxTween.cancelTweensOf(light);
			FlxTween.tween(light, {alpha: 0}, 0.25, {ease: FlxEase.quintIn});
			player.firingTimer = 0;
			if ((player.upgrades.destroyOnLight.value
				&& gameTiles.isTileBackgroundPhysics(gameTiles.tilemap.getTile(player.aimedTile.x, player.aimedTile.y)))
				|| (player.upgrades.canLightSolidTiles.value
					&& gameTiles.isTileForegroundPhysics(gameTiles.tilemap.getTile(player.aimedTile.x, player.aimedTile.y))))
			{
				gameTiles.incinerateTile(gameTiles.getTilesIndex(player.aimedTile.x, player.aimedTile.y));
			}
			else
			{
				var fallingTile = gameTiles.meltTile(gameTiles.getTilesIndex(player.aimedTile.x, player.aimedTile.y));
				if (fallingTile != null)
				{
					fallingTiles.add(fallingTile);
				}
			}
		}
	}

	function playerAimed()
	{
		if (player.fireCooldown)
		{
			return;
		}
		if (player.aiming)
		{
			firePlayer();
		}
		else if (!player.busyFiring())
		{
			if (setPlayerAiming())
			{
				FlxG.sound.play("assets/sounds/combust.mp3", 1, false);
				player.aiming = true;
				bgSnowscape.pause();
				fgSnowscape.pause();
			}
		}
	}

	function setPlayerAiming()
	{
		var pos:TilePosition = player.getTilePosCenter(cast(gameTiles.tilemap.width / gameTiles.tilemap.widthInTiles, Int));
		var posWithFaced:TilePosition = player.getTilePosCenter(cast(gameTiles.tilemap.width / gameTiles.tilemap.widthInTiles, Int));
		posWithFaced.x += player.facing == RIGHT ? 1 : -1;

		var leastDistance:Int = 9999;
		var leastDistanceIndex:Int = null;
		var longDistance:Int = -1;
		var longDistanceIndex:Int = null;

		// Player can't fire until this is done being tweened
		player.fireCooldown = true;

		aimCircles.revive();
		aimCircles.forEachAlive({
			function(entity:AimCircle)
			{
				entity.kill();
			}
		});

		var allTilesIncludingNonavailable = new Array<TilePosition>();

		for (i in cast(Math.max(0,
			pos.y - Math.floor(player.upgrades.range.value) - 1), Int)...cast(Math.min(gameTiles.tilemap.heightInTiles,
				pos.y + Math.ceil(player.upgrades.range.value) + 1)))
		{
			for (j in cast(Math.max(0,
				pos.x - Math.floor(player.upgrades.range.value)), Int)...cast(Math.min(gameTiles.tilemap.widthInTiles,
					pos.x + Math.ceil(player.upgrades.range.value) + 1)))
			{
				var circlePos = new TilePosition(j, i);
				if (pos.squaredDistanceTo(circlePos) > player.upgrades.range.value * player.upgrades.range.value
					&& new TilePosition(pos.x, pos.y - 1).squaredDistanceTo(circlePos) > player.upgrades.range.value * player.upgrades.range.value)
				{
					continue;
				}
				allTilesIncludingNonavailable.push(circlePos);
				if (/*(gameTiles.isTileBackgroundPhysics(gameTiles.tilemap.getTile(j, i)) && !player.upgrades.canLightSolidTiles.value)
					|| ( */ gameTiles.isTilePhysics(gameTiles.tilemap.getTile(j, i)) /* && player.upgrades.canLightSolidTiles.value )*/)
				{
					var circle:AimCircle = aimCircles.recycle(AimCircle, null, true);
					circle.positionCircle(j, i, cast(gameTiles.tilemap.width / gameTiles.tilemap.widthInTiles));
					var circleDist = posWithFaced.squaredDistanceTo(circlePos);
					if (circleDist < leastDistance)
					{
						leastDistance = circleDist;
						leastDistanceIndex = aimCircles.members.indexOf(circle);
					}
					if (circlePos.squaredDistanceTo(pos) > longDistance)
					{
						longDistance = circleDist;
						longDistanceIndex = aimCircles.members.indexOf(circle);
					}
					circle.revive();
					circle.setCircleActive(false, false);
					circle.fadeInTween(getCircleAnimationLength(new TilePosition(j, i), pos, player.upgrades.range.value, 0.1, true));
				}
			}
		}
		if (leastDistanceIndex == null)
		{
			// empty
			playerMessage.fadeInOut("Nothing Meltable");
			var longestAmt:Float = -1;
			for (i in allTilesIncludingNonavailable)
			{
				var circle:AimCircle = aimCircles.recycle(AimCircle, null, true);
				circle.setCircleX();
				circle.positionCircle(i.x, i.y, cast gameTiles.tilemap.width / gameTiles.tilemap.widthInTiles);
				circle.revive();
				var begin:Float = getCircleAnimationLength(i, pos, player.upgrades.range.value, 0.25, true);
				var out:Float = getCircleAnimationLength(i, pos, player.upgrades.range.value, 0.25, false);
				if (begin + out > longestAmt)
				{
					longestAmt = begin + out;
				}
				circle.fadeInTween(begin, function()
				{
					circle.fadeOutTween(out);
				});
			}
			new FlxTimer().start(longestAmt, function(_)
			{
				player.fireCooldown = false;
			});
			return false;
		}
		// Once final circle fades in, allow the player to start doing things again
		new FlxTimer().start(getCircleAnimationLength(new TilePosition(aimCircles.members[longDistanceIndex].tileX,
			aimCircles.members[longDistanceIndex].tileY), pos, player.upgrades.range.value, 0.1,
			true),
			function(_)
			{
				player.fireCooldown = false;
			});

		setCurrentAimCircle(leastDistanceIndex);

		FlxTween.cancelTweensOf(light);
		FlxTween.tween(light, {alpha: 1}, 0.5, {ease: FlxEase.quintIn});

		return true;
	}

	// Slow fade == true is slower, better for fade-ins.
	inline function getCircleAnimationLength(circlePos:TilePosition, playerPos:TilePosition, maxRange:Float, minLength:Float = 0.1, slowFade:Bool)
	{
		return slowFade ? (Math.max(minLength,
			circlePos.distanceTo(playerPos) / maxRange / 3)) : (Math.max(minLength, circlePos.distanceTo(playerPos) / (maxRange) / 10.0));
	}

	function resetStats()
	{
		player.upgrades = new PlayerUpgrades();
		hud.updateMoney(player.upgrades.money);
		levelToLoad = "tutoriallevel.json";
		saveTimer = SAVE_TIME;
		latestCheckpoint = -1;
	}

	function updatePlayerAiming()
	{
		if (player.aiming)
		{
			if (!cameraTweening && cameraZoomedOut())
			{
				zoomCameraIn();
			}
		}
		else
		{
			if (!cameraTweening && cameraZoomedIn())
			{
				zoomCameraOut();
			}
		}
		if (player.fire.check() && player.firingTimer == 0)
		{
			playerAimed();
			return;
		}
		if (!player.aiming)
		{
			return;
		}

		if (player.cancelFire.check())
		{
			firePlayerCancel();
		}

		var newPos = new TilePosition(0, 0);
		if (player.aimUp.check())
		{
			newPos.y -= 1;
		}
		else if (player.aimLeft.check())
		{
			newPos.x -= 1;
		}
		else if (player.aimRight.check())
		{
			newPos.x += 1;
		}
		else if (player.aimDown.check())
		{
			newPos.y += 1;
		}

		if (newPos.x + newPos.y == 0)
		{
			return;
		}

		var leastDist:Int = 9999;
		var leastIndex:Int = null;

		var currentCircle = aimCircles.members[currentAimCircle];

		var posToBeat = new TilePosition(currentCircle.tileX, currentCircle.tileY);
		posToBeat.x += newPos.x;
		posToBeat.y += newPos.y;
		for (i in 0...aimCircles.members.length)
		{
			var member = aimCircles.members[i];
			if (!member.exists || !member.alive || member.alpha == 0)
			{
				continue;
			}
			if ((member.x == currentCircle.tileX && member.y == currentCircle.tileY) || !member.exists || !member.visible)
			{
				continue;
			}
			var pos = new TilePosition(member.tileX, member.tileY);
			if ((member.tileX - currentCircle.tileX) / Math.abs(member.tileX - currentCircle.tileX) != newPos.x
				&& (member.tileY - currentCircle.tileY) / Math.abs(member.tileY - currentCircle.tileY) != newPos.y)
			{
				continue;
			}
			var dist = pos.squaredDistanceTo(posToBeat);
			if (dist < leastDist)
			{
				leastIndex = i;
				leastDist = dist;
			}
		}
		if (leastIndex == null)
		{
			return;
		}

		aimCircles.forEachAlive(function(entity:AimCircle)
		{
			entity.animation.play(entity.animation.name, true, false, 0);
			FlxG.camera.shake(0.003, 0.06, null, false);
			entity.bumpTween();
		}, false);
		setCurrentAimCircle(leastIndex);
	}

	function setCurrentAimCircle(index:Int)
	{
		if (currentAimCircle >= 0 && aimCircles.members[currentAimCircle] != null)
			aimCircles.members[currentAimCircle].setCircleActive(false);
		aimCircles.members[index].setCircleActive(true);
		currentAimCircle = index;
		player.facing = (player.x > aimCircles.members[currentAimCircle].x) ? LEFT : RIGHT;
	}

	function firePlayerCancel()
	{
		var playerPos = player.getTilePosCenter(cast(gameTiles.tilemap.width / gameTiles.tilemap.widthInTiles, Int));
		var biggest:Float = 0;
		var biggestIndex:Int = 0;
		player.firingTimer = 0;
		player.aiming = false;
		player.fireCooldown = true;
		FlxG.camera.shake(0.0035, 0.1, null, false);
		playerMessage.fadeInOut("Cancel");
		bgSnowscape.unpause();
		fgSnowscape.unpause();
		FlxTween.cancelTweensOf(light);
		FlxTween.tween(light, {alpha: 0}, 0.25, {ease: FlxEase.quintIn});
		aimCircles.forEachAlive(function(entity:AimCircle)
		{
			var len = new TilePosition(entity.tileX, entity.tileY);
			var speed:Float = getCircleAnimationLength(len, playerPos, player.upgrades.range.value, 0.1, false);
			if (speed > biggest)
			{
				biggest = speed;
				biggestIndex = aimCircles.members.indexOf(entity);
			}
			entity.fadeOutTween(speed);
		});
		new FlxTimer().start(biggest, function(_)
		{
			aimCircles.kill();
			player.fireCooldown = false;
		});
	}

	function firePlayer()
	{
		var currentCircle = aimCircles.members[currentAimCircle];
		player.aiming = false;
		if (currentCircle == null || !currentCircle.exists || !currentCircle.visible)
		{
			return;
		}
		player.aimedTile.setPosition(currentCircle.tileX, currentCircle.tileY);
		player.firingTimer = 0.001;
		FlxG.sound.play("assets/sounds/lighter.mp3", 1, false);
		var playerPos = player.getTilePosCenter(cast(gameTiles.tilemap.width / gameTiles.tilemap.widthInTiles, Int));
		var biggest:Float = 0;
		var biggestIndex:Int = 0;
		player.fireCooldown = true;
		FlxG.camera.shake(0.007, 0.1, null, false);
		// player.upgrades.canLightSolidTiles.value;
		var tile = gameTiles.tilemap.getTile(currentCircle.tileX, currentCircle.tileY);
		var tileIsForeground = gameTiles.isTileForegroundPhysics(tile);
		playerMessage.fadeInOut(((!tileIsForeground && player.upgrades.destroyOnLight.value)
			|| (tileIsForeground && player.upgrades.canLightSolidTiles.value)) ? "Melting" : "Thawing",
			player.upgrades.lightSpeed.value / 3);
		aimCircles.forEachAlive(function(entity:AimCircle)
		{
			var len = new TilePosition(entity.tileX, entity.tileY);
			var speed:Float = getCircleAnimationLength(len, playerPos, player.upgrades.range.value, 0.1, false);
			if (speed > biggest)
			{
				biggest = speed;
				biggestIndex = aimCircles.members.indexOf(entity);
			}
			entity.fadeOutTween(speed);
		});
		new FlxTimer().start(biggest, function(_)
		{
			aimCircles.kill();
			player.fireCooldown = false;
		});
	}

	function bakeLighting(lightingMap:FlxTilemap)
	{
		// Starts at tile id 12

		// 12: Bottom empty
		// 13: Right empty
		// 14: Left empty
		// 15: Top empty
		// 16: Bottom right empty
		// 17: Bottom left empty
		// 18: Solid
		// 19: Top right empty
		// 20: Top left empty
		// 21: Diagonal positive slope
		// 22: Top left solid
		// 23: Top right solid
		// 24: Diagonal negative slope
		// 25: Bottom left solid
		// 26: Bottom right solid
		for (i in 0...lightingMap.heightInTiles)
		{
			for (j in 0...lightingMap.widthInTiles)
			{
				if (!gameTiles.tileAtIsFoundation(j, i))
				{
					continue;
				}
				var leftFull:Bool = gameTiles.tileAtIsFoundation(j - 1, i) && isTileShaded(j - 1, i);
				var rightFull:Bool = gameTiles.tileAtIsFoundation(j + 1, i) && isTileShaded(j + 1, i);
				var topFull:Bool = gameTiles.tileAtIsFoundation(j, i - 1) && isTileShaded(j, i - 1);
				var bottomFull:Bool = gameTiles.tileAtIsFoundation(j, i + 1) && isTileShaded(j, i + 1);

				var topleftFull:Bool = gameTiles.tileAtIsFoundation(j - 1, i - 1) && isTileShaded(j - 1, i - 1);
				var toprightFull:Bool = gameTiles.tileAtIsFoundation(j + 1, i - 1) && isTileShaded(j + 1, i - 1);
				var bottomleftFull:Bool = gameTiles.tileAtIsFoundation(j - 1, i + 1) && isTileShaded(j - 1, i + 1);
				var bottomrightFull:Bool = gameTiles.tileAtIsFoundation(j + 1, i + 1) && isTileShaded(j + 1, i + 1);

				// horizontal/vertical bits
				if (leftFull && topFull && !bottomFull && rightFull)
				{
					lightingMap.setTile(j, i, 12);
				}
				if (leftFull && topFull && bottomFull && !rightFull)
				{
					lightingMap.setTile(j, i, 13);
				}
				if (!leftFull && topFull && bottomFull && rightFull)
				{
					lightingMap.setTile(j, i, 14);
				}
				if (leftFull && !topFull && bottomFull && rightFull)
				{
					lightingMap.setTile(j, i, 15);
				}

				// sticky-outer bits
				if (rightFull && topFull && !leftFull && !bottomFull)
				{
					lightingMap.setTile(j, i, 23);
				}
				if (leftFull && topFull && !rightFull && !bottomFull)
				{
					lightingMap.setTile(j, i, 22);
				}
				if (leftFull && bottomFull && !topFull && !rightFull)
				{
					lightingMap.setTile(j, i, 25);
				}
				if (rightFull && bottomFull && !topFull && !leftFull)
				{
					lightingMap.setTile(j, i, 26);
				}

				// inner bits and solid
				if (leftFull && topFull && bottomFull && rightFull)
				{
					if (!bottomrightFull && !bottomleftFull && topleftFull && toprightFull)
					{
						lightingMap.setTile(j, i, 12);
					}
					else if (!topleftFull && !toprightFull && bottomleftFull && bottomrightFull)
					{
						lightingMap.setTile(j, i, 15);
					}
					else if (!topleftFull && !bottomleftFull && toprightFull && bottomrightFull)
					{
						lightingMap.setTile(j, i, 14);
					}
					else if (!toprightFull && !bottomrightFull && topleftFull && bottomleftFull)
					{
						lightingMap.setTile(j, i, 13);
					}
					else if (!topleftFull && !bottomrightFull && bottomleftFull && toprightFull)
					{
						lightingMap.setTile(j, i, 21);
					}
					else if (!topleftFull && !toprightFull && topleftFull && bottomrightFull)
					{
						lightingMap.setTile(j, i, 24);
					}
					else if (!toprightFull)
					{
						lightingMap.setTile(j, i, 19);
					}
					else if (!topleftFull)
					{
						lightingMap.setTile(j, i, 20);
					}
					else if (!bottomrightFull)
					{
						lightingMap.setTile(j, i, 16);
					}
					else if (!bottomleftFull)
					{
						lightingMap.setTile(j, i, 17);
					}
					else
					{
						lightingMap.setTile(j, i, 18);
					}
				}
			}
		}
	}

	function isTileShaded(j:Int, i:Int)
	{
		if (!gameTiles.tileAtIsFoundation(j, i))
		{
			return false;
		}
		var leftFull:Bool = gameTiles.tileAtIsFoundation(j - 1, i);
		var rightFull:Bool = gameTiles.tileAtIsFoundation(j + 1, i);
		var topFull:Bool = gameTiles.tileAtIsFoundation(j, i - 1);
		var bottomFull:Bool = gameTiles.tileAtIsFoundation(j, i + 1);

		var topleftFull:Bool = gameTiles.tileAtIsFoundation(j - 1, i - 1);
		var toprightFull:Bool = gameTiles.tileAtIsFoundation(j + 1, i - 1);
		var bottomleftFull:Bool = gameTiles.tileAtIsFoundation(j - 1, i + 1);
		var bottomrightFull:Bool = gameTiles.tileAtIsFoundation(j + 1, i + 1);

		// horizontal/vertical bits
		if (leftFull && topFull && !bottomFull && rightFull)
		{
			return true;
		}
		if (leftFull && topFull && bottomFull && !rightFull)
		{
			return true;
		}
		if (!leftFull && topFull && bottomFull && rightFull)
		{
			return true;
		}
		if (leftFull && !topFull && bottomFull && rightFull)
		{
			return true;
		}

		// sticky-outer bits
		if (rightFull && topFull && !leftFull && !bottomFull)
		{
			return true;
		}
		if (leftFull && topFull && !rightFull && !bottomFull)
		{
			return true;
		}
		if (leftFull && bottomFull && !topFull && !rightFull)
		{
			return true;
		}
		if (rightFull && bottomFull && !topFull && !leftFull)
		{
			return true;
		}

		// inner bits and solid
		if (leftFull && topFull && bottomFull && rightFull)
		{
			if (!bottomrightFull && !bottomleftFull && topleftFull && toprightFull)
			{
				return true;
			}
			else if (!topleftFull && !toprightFull && bottomleftFull && bottomrightFull)
			{
				return true;
			}
			else if (!topleftFull && !bottomleftFull && toprightFull && bottomrightFull)
			{
				return true;
			}
			else if (!toprightFull && !bottomrightFull && topleftFull && bottomleftFull)
			{
				return true;
			}
			else if (!topleftFull && !bottomrightFull && bottomleftFull && toprightFull)
			{
				return true;
			}
			else if (!topleftFull && !toprightFull && topleftFull && bottomrightFull)
			{
				return true;
			}
			else if (!toprightFull)
			{
				return true;
			}
			else if (!topleftFull)
			{
				return true;
			}
			else if (!bottomrightFull)
			{
				return true;
			}
			else if (!bottomleftFull)
			{
				return true;
			}
			else
			{
				return true;
			}
		}
		return false;
	}

	function loadLevel(file:String)
	{
		var loader:FlxOgmo3Loader = new FlxOgmo3Loader("assets/data/tilemaps.ogmo", "assets/data/" + file);

		gameTiles = new WinterTilemap(loader.loadTilemap("assets/images/tiles.png", "foreground"),
			loader.loadTilemap("assets/images/ladderTiles.png", "ladders"), loader.loadTilemap("assets/images/decor.png", "decor"));

		levelName = loader.getLevelValue("values").nameText;

		gameTiles.tilemap.setTileProperties(0, NONE, null, null, 48);
		gameTiles.tilemap.setTileProperties(3, ANY, null, null, 18);
		gameTiles.tilemap.setTileProperties(30, ANY, null, null, 9);

		add(gameTiles.tilemap);

		var stopTheCount = 0;
		for (i in 0...gameTiles.tilemap.heightInTiles)
		{
			for (j in 0...gameTiles.tilemap.widthInTiles)
			{
				if (gameTiles.isTileBackgroundPhysics(gameTiles.tilemap.getTile(j, i))
					|| gameTiles.isTileForegroundPhysics(gameTiles.tilemap.getTile(j, i)))
				{
					stopTheCount++;
				}
			}
		}
		startingDestroyableTiles = stopTheCount;

		fallingTiles = new FlxTypedGroup<FallingTile>();

		add(fallingTiles);

		lightingMap = loader.loadTilemap("assets/images/decor.png", "lighting");
		lightingMap.useScaleHack = false;
		bakeLighting(lightingMap);
		add(lightingMap);

		loader.loadEntities(loadLightEntities, "lightEntities");

		shops = new Array<Shop>();
		loader.loadEntities(loadShopEntities, "shops");
		loader.loadEntities(loadShopkeeperEntities, "shopkeepers");

		gameTiles.ladderTiles.setTileProperties(0, NONE, null, null, 3);
		gameTiles.ladderTiles.setTileProperties(3, UP, null, null);

		add(gameTiles.ladderTiles);

		add(gameTiles.decorTiles);

		loader.loadEntities(loadTriggers, "triggers");
		add(levelTriggers);

		gameTiles.tilemap.follow(FlxG.camera);

		loader.loadEntities(loadEntities, "entities");

		if (player == null)
		{
			FlxG.log.warn("Player not placed in level " + file + "!");
		}
	}
}
