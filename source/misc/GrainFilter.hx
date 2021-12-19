package misc;

// https://github.com/HaxeFlixel/flixel-demos/blob/master/Effects/Filters/source/PlayState.hx
import openfl.Lib;
import openfl.display.Shader;
import openfl.filters.ShaderFilter;
#if (openfl >= "8.0.0")
import misc.openfl8.*;
#else
import misc.openfl3.*;
#end

class GrainFilter extends ShaderFilter
{
	public static function create():GrainFilter
	{
		var grainShader = new Grain();
		return new GrainFilter(grainShader);
	}

	public function new(grain:Grain)
	{
		super(grain);
	}

	public function update()
	{
		#if (openfl >= "8.0.0")
		cast(shader, Grain).uTime.value = [Lib.getTimer() / 1000];
		#else
		cast(shader, Grain).uTime = Lib.getTimer() / 1000;
		#end
	}
}
