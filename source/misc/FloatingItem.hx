package misc;

import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;

class FloatingItem extends FlxTypedGroup<FlxSprite>
{
	var counter:Float = 0;

	var item:FlxSprite;
	var frameOutline:FlxSprite;
	var controls:FlxText;

	public var selected:Bool;

	public var doFloat:Bool;

	public function new(x:Float, y:Float, path:String, selected:Bool = false, makeRed:Bool = false, doFloat:Bool = true)
	{
		super();

		this.doFloat = doFloat;

		item = new FlxSprite(x, y);
		item.loadGraphic(path);
		frameOutline = new FlxSprite(x - 3, y - 3);
		frameOutline.loadGraphic("assets/images/upgradeFrame.png");
		controls = new FlxText(x + (item.width / 2) - 50, y + item.height + 25, 100, "", 8);
		controls.alignment = CENTER;
		setSelected(selected, makeRed);
		add(item);
		add(frameOutline);
		add(controls);

		forEach(function(entity)
		{
			entity.scrollFactor.set(0, 0);
		});
	}

	override public function update(elapsed:Float)
	{
		counter += elapsed;
		if (doFloat)
		{
			item.y += Math.sin(counter * 4) * 0.2;
			frameOutline.y += Math.sin(counter * 4) * 0.2;
		}
		controls.x += Math.sin(counter * 4) * 0.1;
		super.update(elapsed);
	}

	public function setControlText(left = false, right = false, buy = false)
	{
		controls.text = (left ? "[<]" : "") + (buy ? " [Z] To Buy" : "") + (right ? " [>]" : "");
	}

	public function setSelected(selected:Bool, makeRed:Bool = false)
	{
		this.frameOutline.visible = selected;
		this.selected = selected;
		this.controls.visible = selected;
		if (makeRed)
			this.frameOutline.color = 0xFFFF0000;
		else
			this.frameOutline.color = 0xFFFFFFFF;
	}
}
