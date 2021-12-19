package game;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.actions.FlxAction;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import js.lib.intl.NumberFormat.CurrencyDisplay;
import misc.CurrencyOverlay;
import misc.FloatingItem;
import misc.GrainFilter;
import misc.UpgradeType;
import misc.UpgradeTypes;
import openfl.display.Sprite;
import player.PlayerUpgrades;
import player.Upgrade;

class UpgradesState extends FlxSubState
{
	public var bg:FlxSprite = null;

	public var selection:Int = 0;
	public var upgradeTypeList = new Array<UpgradeType>();
	public var itemList:Array<FloatingItem>;
	public var topText:Array<FlxText>;

	public var currencyOverlay:CurrencyOverlay;

	public var left:FlxAction;
	public var right:FlxAction;
	public var buy:FlxAction;
	public var closeButton:FlxAction;

	public var unlocked:PlayerUpgrades;

	public var targetCamera:FlxCamera;

	public var escToQuit:FlxText;

	var justLoadedSoDontBuyImmediately = false;

	public function new(left:FlxAction, right:FlxAction, buy:FlxAction, closeButton:FlxAction)
	{
		super();
		this.left = left;
		this.right = right;
		this.buy = buy;
		this.closeButton = closeButton;
	}

	override public function create()
	{
		super.create();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		Main.grain.update();

		updateInput();

		var x = 0;
		for (i in 0...itemList.length)
		{
			if (x == selection)
			{
				itemList[i].setSelected(true, !canAffordUpgrade(upgradeTypeList[i]));
				itemList[i].setControlText(i > 0, i < itemList.length - 1, canAffordUpgrade(upgradeTypeList[i]));
				topText[i].color = 0xFFFFFFFF;
			}
			else
			{
				itemList[i].setSelected(false);
				topText[i].color = 0xFFAAAAAA;
			}
			x++;
		}
	}

	public function updateInput()
	{
		if (closeButton.check())
		{
			fadeOutAndClose();
		}
		else if (left.check())
		{
			targetCamera.shake(0.006, 0.04);
			selection = cast Math.max(selection - 1, 0);
		}
		else if (right.check())
		{
			targetCamera.shake(0.006, 0.04);
			selection = cast Math.min(selection + 1, itemList.length - 1);
		}
		else if (buy.check() && !justLoadedSoDontBuyImmediately)
		{
			targetCamera.shake(0.012, 0.04);
			if (!canAffordUpgrade(upgradeTypeList[selection]))
			{
				return;
			}
			unlocked.money -= upgradeUpgrade(upgradeTypeList[selection]);
			setUpgrades(unlocked, upgradeTypeList);
			currencyOverlay.bump();
			selection = cast Math.min(selection, upgradeTypeList.length);
			FlxG.sound.play("assets/sounds/coin.mp3", 1, false);
		}
		justLoadedSoDontBuyImmediately = false;
	}

	public function upgradeUpgrade(upgrade:UpgradeType):Int
	{
		if (unlocked.canLightSolidTiles.upgradeType == upgrade)
		{
			return unlocked.canLightSolidTiles.upgrade(unlocked.money);
		}
		else if (unlocked.destroyOnLight.upgradeType == upgrade)
		{
			return unlocked.destroyOnLight.upgrade(unlocked.money);
		}
		else if (unlocked.lightSpeed.upgradeType == upgrade)
		{
			return unlocked.lightSpeed.upgrade(unlocked.money);
		}
		else if (unlocked.range.upgradeType == upgrade)
		{
			return unlocked.range.upgrade(unlocked.money);
		}
		return 0;
	}

	public function getUpgradeCost(upgrade:UpgradeType):Int
	{
		if (unlocked.canLightSolidTiles.upgradeType == upgrade)
		{
			return unlocked.canLightSolidTiles.getCost();
		}
		else if (unlocked.destroyOnLight.upgradeType == upgrade)
		{
			return unlocked.destroyOnLight.getCost();
		}
		else if (unlocked.lightSpeed.upgradeType == upgrade)
		{
			return unlocked.lightSpeed.getCost();
		}
		else if (unlocked.range.upgradeType == upgrade)
		{
			return unlocked.range.getCost();
		}
		return 99999;
	}

	public inline function canAffordUpgrade(upgrade:UpgradeType):Bool
	{
		return unlocked.money >= getUpgradeCost(upgrade);
	}

	public function setUpgrades(unlocked:PlayerUpgrades, available:Array<UpgradeType>, fadeIn:Bool = false)
	{
		for (i in available)
		{
			if (i == null)
			{
				available.remove(i);
			}
		}
		if (targetCamera == null)
		{
			targetCamera = new FlxCamera(0, 0, FlxG.camera.width, FlxG.camera.height, FlxG.camera.initialZoom);
			targetCamera.useBgAlphaBlending = true;
			targetCamera.bgColor = 0;
			FlxG.cameras.add(targetCamera, false);
		}
		forEach(function(entity)
		{
			if (entity != bg)
			{
				entity.kill();
			}
		}, true);
		if (bg == null)
		{
			bg = new FlxSprite(0, 0).loadGraphic("assets/images/fire.png", true, 320, 240);
			bg.animation.add("idle", [0, 1, 2, 1], 4);
			bg.animation.play("idle");
			add(bg);
		}
		justLoadedSoDontBuyImmediately = true;

		var cost:Array<Int> = new Array<Int>();
		var suffix:Array<String> = new Array<String>();
		var value:Array<Float> = new Array<Float>();
		var counter = 0;
		for (obj in 0...available.length)
		{
			var i = available[obj];
			// this code I hate but i'm lazy
			if (unlocked.canLightSolidTiles.upgradeType == i)
			{
				FlxG.log.add(unlocked.canLightSolidTiles.getCost() + "," + unlocked.money);
				cost[obj] = unlocked.canLightSolidTiles.getCost();
				if (!unlocked.canLightSolidTiles.canUpgradeStepSize())
				{
					available[obj] = UpgradeTypes.SOLD;
				}
			}
			else if (unlocked.destroyOnLight.upgradeType == i)
			{
				cost[obj] = unlocked.destroyOnLight.getCost();
				if (!unlocked.destroyOnLight.canUpgradeStepSize())
				{
					available[obj] = UpgradeTypes.SOLD;
				}
			}
			else if (unlocked.lightSpeed.upgradeType == i)
			{
				cost[obj] = unlocked.lightSpeed.getCost();
				if (!unlocked.lightSpeed.canUpgradeStepSize())
				{
					available[obj] = UpgradeTypes.SOLD;
				}
				else
				{
					value[obj] = cast unlocked.lightSpeed.value + unlocked.lightSpeed.stepSize;
					suffix[obj] = "s";
				}
			}
			else if (unlocked.range.upgradeType == i)
			{
				cost[obj] = unlocked.range.getCost();
				if (!unlocked.range.canUpgradeStepSize())
				{
					available[obj] = UpgradeTypes.SOLD;
				}
				else
				{
					value[obj] = cast unlocked.range.value + unlocked.range.stepSize;
					suffix[obj] = " Tiles";
				}
			}
		}

		upgradeTypeList = new Array<UpgradeType>();
		topText = new Array<FlxText>();
		itemList = new Array<FloatingItem>();

		var xOff = available.length == 2 ? 15 : 100;

		for (i in 0...available.length)
		{
			var upgradeType = available[i];
			var xAmt = xOff + (i * 165);
			var yAmt = 165;

			upgradeTypeList.push(upgradeType);

			var ice = new FlxSprite(xAmt, yAmt);
			ice.loadGraphic("assets/images/iceblock.png");
			add(ice);

			var item = new FloatingItem(xAmt + 25, yAmt - 50, upgradeType.path, false, false, upgradeType != UpgradeTypes.SOLD);
			add(item);

			itemList.push(item);

			var text = new FlxText(xAmt
				+ ice.width / 2
				- 100, yAmt
				- 90, 200,
				upgradeType.name
				+ ((value[i] >= 0) ? (" (" + value[i] + suffix[i] + ")") : ""), 16);

			text.alignment = CENTER;
			topText.push(text);
			add(text);
			if (upgradeType != UpgradeTypes.SOLD)
			{
				var text2 = new FlxText(xAmt + ice.width / 2 - 100, yAmt - 70, 200, "Costs " + cost[i] + " Ice Crystals", 8);
				text2.alignment = CENTER;
				text2.setFormat(null, 8, 0xFFBBCCFF, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF112266);
				add(text2);
			}
		}

		currencyOverlay = new CurrencyOverlay(5, 5, unlocked.money);
		add(currencyOverlay);

		escToQuit = new FlxText(FlxG.width - 205, 10, 200, "[X] To Leave");
		escToQuit.setFormat(null, 16, FlxColor.BLACK);
		escToQuit.alignment = RIGHT;
		add(escToQuit);

		this.unlocked = unlocked;

		forEachOfType(FlxSprite, function(entity)
		{
			entity.scrollFactor.set(0, 0);
			entity.camera = targetCamera;
			if (fadeIn)
			{
				if (entity == bg)
				{
					return;
				}
				if (entity == escToQuit || entity == currencyOverlay.icon || entity == currencyOverlay.moneyText)
				{
					FlxTween.tween(entity, {alpha: 1}, 2, {ease: FlxEase.quintIn});
				}
				else
				{
					entity.y += 200;
					FlxTween.tween(entity, {y: entity.y - 200}, 1, {ease: FlxEase.quadOut});
				}
			}
		}, true);
		if (fadeIn)
		{
			bg.alpha = 0;
			FlxTween.tween(bg, {alpha: 1}, 0.25, {ease: FlxEase.quintIn});
		}
	}

	public function fadeOutAndClose()
	{
		forEachOfType(FlxSprite, function(entity)
		{
			entity.camera = targetCamera;
			FlxTween.cancelTweensOf(entity);
			if (entity == bg)
			{
				return;
			}
			else if (entity == escToQuit || entity == currencyOverlay.icon || entity == currencyOverlay.moneyText)
			{
				FlxTween.tween(entity, {alpha: 0}, 0.5, {ease: FlxEase.quadIn});
			}
			else
			{
				FlxTween.tween(entity, {y: entity.y + 300}, 1, {ease: FlxEase.quadIn});
			}
		}, true);
		new FlxTimer().start(0.5, function(_)
		{
			FlxTween.tween(bg, {alpha: 0}, 0.5, {
				ease: FlxEase.quintIn,
				onComplete: function(_)
				{
					close();
				}
			});
		});
	}
}
