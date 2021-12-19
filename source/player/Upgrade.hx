package player;

import flixel.FlxG;
import misc.UpgradeType;

class Upgrade<T>
{
	public var value:T;

	public var flatCost:Int = null;
	public var costFunction:T->Int = null;

	public var stepSize:T;
	public var maxUpgrade:T;

	public var name = "Unnamed Upgrade";

	public var upgradeType:UpgradeType;

	// For bools, stepSize should be true
	public function new(upgradeType:UpgradeType, setValue:T, name:String, stepSize:T, maxUpgrade:T, flatCost:Int = null, costFunction:T->Int = null)
	{
		this.value = setValue;
		this.flatCost = flatCost;
		this.costFunction = costFunction;
		this.name = name;
		this.stepSize = stepSize;
		this.maxUpgrade = maxUpgrade;
		this.upgradeType = upgradeType;
	}

	public function getCost():Int
	{
		if (flatCost != null)
		{
			return flatCost;
		}
		else if (costFunction != null)
		{
			return costFunction(value);
		}
		else
		{
			FlxG.log.warn("Cost was empty!");
			return 0;
		}
	}

	public function canUpgrade(money:Int):Bool
	{
		/*if (Std.isOfType(value, Int))
			{
				return (money >= getCost()
					&& ((cast(stepSize, Int) < 0 && cast(value, Int) + cast(stepSize, Int) >= cast(maxUpgrade, Int))
						|| (cast(stepSize, Int) > 0 && cast(value, Int) + cast(stepSize, Int) <= cast(maxUpgrade, Int))));
			}
			else if (Std.isOfType(value, Float))
			{
				return (money >= getCost()
					&& ((cast(stepSize, Float) < 0 && cast(value, Float) + cast(stepSize, Float) >= cast(maxUpgrade, Float))
						|| (cast(stepSize, Float) > 0 && cast(value, Float) + cast(stepSize, Float) <= cast(maxUpgrade, Float))));
			}
			else if (Std.isOfType(value, Bool))
			{
				return (money >= getCost() && cast(value, Bool) == false);
			}
			return false; */
		return canUpgradeStepSize() && canAfford(money);
	}

	public function canUpgradeStepSize():Bool
	{
		if (Std.isOfType(stepSize, Float))
		{
			return (cast(stepSize, Float) < 0 && cast(value, Float) + cast(stepSize, Float) >= cast(maxUpgrade, Float))
				|| (cast(stepSize, Float) > 0 && cast(value, Float) + cast(stepSize, Float) <= cast(maxUpgrade, Float));
		}
		else if (Std.isOfType(stepSize, Int))
		{
			return (cast(stepSize, Int) < 0 && cast(value, Int) + cast(stepSize, Int) >= cast(maxUpgrade, Int))
				|| (cast(stepSize, Int) > 0 && cast(value, Int) + cast(stepSize, Int) <= cast(maxUpgrade, Int));
		}
		else if (Std.isOfType(stepSize, Bool))
		{
			return cast(value, Bool) == false;
		}
		return false;
	}

	public inline function canAfford(money:Int):Bool
	{
		return money >= getCost();
	}

	// Returns cost to be used for subtracting from money
	// Returns -1 if couldn't buy
	public function upgrade(money:Int):Int
	{
		if (!canUpgrade(money))
		{
			return -1;
		}
		var cost = getCost();
		if (Std.isOfType(stepSize, Int))
		{
			var added:Int = cast(value, Int) + cast(stepSize, Int);
			value = cast added;
		}
		else if (Std.isOfType(stepSize, Float))
		{
			var added:Float = cast(value, Float) + cast(stepSize, Float);
			value = cast added;
		}
		else if (Std.isOfType(stepSize, Bool))
		{
			value = stepSize;
		}
		return cost;
	}
}
