package game;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import misc.CurrencyOverlay;
import openfl.geom.Rectangle;
import tiles.TilePosition;
import tiles.WinterTilemap;

class PlayHud extends FlxTypedGroup<FlxSprite>
{
	// Minimap colors:
	// Background, dark, medium, light, Shop light, shop dark
	public static final TILE_COLORS:Array<Int> = [0xFF233A6B, 0xFF30698C, 0xFF3C9CD5, 0xFF9DCFED, 0xFF5F4726, 0xFF292520];
	public static final LADDER_COLOR:Int = 0xFF0D5877;
	// Warm orange, hopefully
	public static final PLAYER_COLOR:Int = 0xFFD59841;
	public static final PARALLAX_SCROLLERS_COLORS:Array<Int> = [0xFF02141F, 0xFF032030];

	var currencyOverlay:CurrencyOverlay;

	var minimapOverlay:FlxSprite;
	var minimap:FlxSprite;

	var parallaxRects:Array<Rectangle>;

	var floatingTexts:FlxTypedGroup<FlxText>;

	public var playHudCamera:FlxCamera;

	public var resetText:FlxText;

	public function new(money:Int = 0, floatingTexts:FlxTypedGroup<FlxText>, levelSize:TilePosition, isARestartedLevel:Bool = false)
	{
		super();

		playHudCamera = new FlxCamera(0, 0, FlxG.camera.width, FlxG.camera.height, FlxG.camera.initialZoom);
		playHudCamera.useBgAlphaBlending = true;
		playHudCamera.bgColor = 0;
		FlxG.cameras.add(playHudCamera, false);

		playHudCamera.fade(null, 1, true);

		this.floatingTexts = floatingTexts;

		minimap = new FlxSprite(5 + 3, 5 + 3);
		minimap.makeGraphic(74, 44, 0xFF233A6B);

		add(minimap);

		minimapOverlay = new FlxSprite(5, 5);
		minimapOverlay.loadGraphic("assets/images/minimap.png", false);

		add(minimapOverlay);

		parallaxRects = new Array<Rectangle>();
		for (i in 0...50)
		{
			parallaxRects.push(new Rectangle(Math.random() * levelSize.x, Math.random() * levelSize.y / 2, Math.random() * 20 + (i % 2 == 0 ? 0 : 10), 200));
		}

		currencyOverlay = new CurrencyOverlay(5, 60, money, isARestartedLevel);

		add(currencyOverlay.icon);
		add(currencyOverlay.moneyText);

		resetText = new FlxText(minimapOverlay.x + minimapOverlay.width + 5, minimapOverlay.y, 0, "[R]estart Level", 8);
		resetText.setFormat(null, 8, 0xFF726219, LEFT, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
		add(resetText);

		forEach(function(entity:FlxSprite)
		{
			entity.scrollFactor.set(0, 0);
			entity.camera = playHudCamera;
		});
	}

	var fromIcon:FlxPoint;
	var fromMoneyText:FlxPoint;
	var fromMinimapOverlay:FlxPoint;
	var fromMinimap:FlxPoint;
	var fromResetText:FlxPoint;

	public function setFadedOut()
	{
		fromMoneyText = currencyOverlay.moneyText.getPosition();
		fromIcon = currencyOverlay.icon.getPosition();
		fromMinimapOverlay = minimapOverlay.getPosition();
		fromMinimap = minimap.getPosition();
		fromResetText = resetText.getPosition();

		currencyOverlay.icon.x = -currencyOverlay.icon.width;
		currencyOverlay.moneyText.x = -currencyOverlay.moneyText.width;

		minimap.x = -minimap.width;
		minimapOverlay.x = -minimapOverlay.width;

		resetText.y = -resetText.height * 5;
	}

	public function fadeIn(duration:Float)
	{
		FlxTween.tween(currencyOverlay.icon, {x: fromIcon.x}, duration / 4, {ease: FlxEase.quadOut});
		FlxTween.tween(currencyOverlay.moneyText, {x: fromMoneyText.x}, duration, {ease: FlxEase.quadOut});

		FlxTween.tween(minimapOverlay, {x: fromMinimapOverlay.x}, duration, {ease: FlxEase.quadOut});
		FlxTween.tween(minimap, {x: fromMinimap.x}, duration, {ease: FlxEase.quadOut});

		FlxTween.tween(resetText, {y: fromResetText.y}, duration, {ease: FlxEase.quadOut});
	}

	public function updateMinimap(gameTiles:WinterTilemap, playerTileX:Float, playerTileY:Float)
	{
		var minimapTileW:Int = 24;
		var minimapTileH:Int = 16;
		var minimapTileSize:Int = 3;

		playerTileY += 0.5;

		var offsetX = playerTileX - Math.floor(playerTileX);
		var offsetY = playerTileY - Math.floor(playerTileY);

		var yPos = 0;
		var xPos = 0;
		// Black fill
		minimap.graphic.bitmap.fillRect(new Rectangle(0, 0, minimapTileW * minimapTileSize, minimapTileH * minimapTileSize), 0xFF01090F);

		// Parallax rects for minimap
		for (i in 0...parallaxRects.length)
		{
			var rect = parallaxRects[i];
			var dist = i % 2 == 0 ? 2.5 : 1.5;
			var clr = PARALLAX_SCROLLERS_COLORS[(i % 2 == 0) ? 0 : 1];
			minimap.graphic.bitmap.fillRect(new Rectangle(Math.round((rect.x * minimapTileSize) - playerTileX / dist),
				Math.round((rect.y * minimapTileSize) - playerTileY / dist), rect.width, rect.height),
				clr);
		}
		minimap.graphic.bitmap.fillRect(new Rectangle(0, Math.floor((gameTiles.tilemap.heightInTiles - playerTileY + minimapTileH / 2) * minimapTileSize),
			minimapTileW * minimapTileSize, 100),
			TILE_COLORS[1]);

		for (i in cast(-minimapTileH / 2, Int)...cast(minimapTileH / 2, Int))
		{
			for (j in cast(-minimapTileW / 2, Int)...cast(minimapTileW / 2, Int))
			{
				var tilemapX:Int = j + Math.floor(playerTileX);
				var tilemapY:Int = i + Math.floor(playerTileY);

				var color = 0;

				if (tilemapX >= 0
					&& tilemapX < gameTiles.tilemap.widthInTiles
					&& tilemapY >= 0
					&& tilemapY < gameTiles.tilemap.heightInTiles)
				{
					if (gameTiles.ladderTiles.getTile(tilemapX, tilemapY) > 0)
					{
						color = LADDER_COLOR;
					}
					else
					{
						var tile = gameTiles.tilemap.getTile(tilemapX, tilemapY);
						if (gameTiles.isTileGround(tile))
						{
							color = TILE_COLORS[1];
						}
						else if (gameTiles.isTileForegroundPhysics(tile))
						{
							color = TILE_COLORS[3];
						}
						else if (gameTiles.isTileBackgroundPhysics(tile))
						{
							color = TILE_COLORS[2];
						}
						else if (gameTiles.isTileForegroundShop(tile))
						{
							color = TILE_COLORS[4];
						}
						else if (gameTiles.isTileBackgroundShop(tile))
						{
							color = TILE_COLORS[5];
						}
						else
						{
							color = 0;
						}
					}
				}

				if (color != 0)
				{
					minimap.graphic.bitmap.fillRect(new Rectangle(Math.round((xPos - offsetX) * minimapTileSize),
						Math.round((yPos - offsetY) * minimapTileSize), minimapTileSize, minimapTileSize),
						color);
				}

				xPos++;
			}
			yPos++;
			xPos = 0;
		}
		minimap.graphic.bitmap.fillRect(new Rectangle((cast(minimapTileW / 2, Int)) * minimapTileSize
			- 1,
			(((cast(minimapTileH / 2, Int)) * minimapTileSize))
			- 2, minimapTileSize, minimapTileSize
			+ 2),
			PLAYER_COLOR);
	}

	public function updateMoney(money:Int, playerPos:FlxPoint = null)
	{
		if (playerPos == null)
		{
			currencyOverlay.moneyAmt = money;
			currencyOverlay.moneyText.text = money + "";
			return;
		}
		var diff:Int = money - currencyOverlay.moneyAmt;
		if (diff == 0)
		{
			return;
		}
		// moneyText.text = money + "";
		var increment:Int = (diff % 2 == 0) ? 2 : 1;

		var prevMoneyAmt = currencyOverlay.moneyAmt;
		currencyOverlay.moneyAmt = money;
		for (i in 0...cast(diff / increment, Int))
		{
			var newText = cast(floatingTexts.recycle(FlxText), FlxText).setFormat(null, 8, 0xFF207DA4, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF135E7B, true);
			newText.setPosition(playerPos.x + Math.random() * 10 - 5, playerPos.y + Math.random() * 10 - 5);
			newText.scrollFactor.set(1, 1);
			newText.text = increment + "";

			var toX = currencyOverlay.icon.x + currencyOverlay.icon.width / 2;
			var toY = currencyOverlay.icon.y + currencyOverlay.icon.height / 2;
			FlxTween.tween(newText.scrollFactor, {x: 0, y: 0}, 1, {ease: FlxEase.quadInOut});
			FlxTween.quadMotion(newText, newText.x, newText.y, ((newText.x + toX) / 2)
				+ Math.random() * 10
				+ 50,
				((newText.y + toY) / 2)
				+ Math.random() * 10
				+ 50, toX, toY, 1, true, {
					ease: FlxEase.quadInOut,
					onComplete: function(_)
					{
						prevMoneyAmt += increment;
						currencyOverlay.moneyText.text = prevMoneyAmt + "";
						currencyOverlay.bump();
						newText.kill();
					}
				});
		}
	}
}
