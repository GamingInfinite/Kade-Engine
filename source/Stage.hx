package;

import flixel.FlxSprite;
import flixel.FlxG;
import flixel.FlxBasic;
import flixel.group.FlxGroup;
import flixel.system.FlxSound;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

typedef StageData =
{
	var objects:Array<StageObject>;
	var characters:Array<CharacterPos>;
	var ?camZoom:Float;
}

typedef StageObject =
{
	var name:String;
	var posX:Int;
	var posY:Int;
	var ?scale:Array<Float>;
	var ?song:String;
	var ?scrollFactor:Array<Float>;
	var ?active:Bool;
	var ?layInFront:Int;
	var ?isDistraction:Bool;
	var ?isMulti:Bool;
	var ?multiNum:Int;
	var ?multiDiff:Array<Int>;
	var ?multiName:String;
	var ?isMoving:Bool;
	var ?isDancer:Bool;
	var ?isAnimated:Bool;
	var ?updateHitbox:Bool;
	var ?visible:Bool;
	var ?groupAdd:Bool;
	var frames:Array<String>;
	var startingAnim:String;
	var animations:Array<ObjectAnim>;
}

typedef ObjectAnim =
{
	var name:String;
	var prefix:String;
	var ?indices:Array<Int>;
	var ?fps:Int;
	var ?looped:Bool;
	var ?song:String;
}

typedef CharacterPos =
{
	var name:String;
	var posX:Float;
	var posY:Float;
}

class Stage extends MusicBeatState
{
	public var curStage:String = '';
	public var camZoom:Float; // The zoom of the camera to have at the start of the game
	public var hideLastBG:Bool = false; // True = hide last BGs and show ones from slowBacks on certain step, False = Toggle visibility of BGs from SlowBacks on certain step
	// Use visible property to manage if BG would be visible or not at the start of the game
	public var tweenDuration:Float = 2; // How long will it tween hiding/showing BGs, variable above must be set to True for tween to activate
	public var toAdd:Array<Dynamic> = []; // Add BGs on stage startup, load BG in by using "toAdd.push(bgVar);"
	// Layering algorithm for noobs: Everything loads by the method of "On Top", example: You load wall first(Every other added BG layers on it), then you load road(comes on top of wall and doesn't clip through it), then loading street lights(comes on top of wall and road)
	public var swagBacks:Map<String,
		Dynamic> = []; // Store BGs here to use them later (for example with slowBacks, using your custom stage event or to adjust position in stage debug menu(press 8 while in PlayState with debug build of the game))
	public var swagGroup:Map<String, FlxTypedGroup<Dynamic>> = []; // Store Groups
	public var animatedBacks:Array<FlxSprite> = []; // Store animated backgrounds and make them play animation(Animation must be named Idle!! Else use swagGroup/swagBacks and script it in stepHit/beatHit function of this file!!)
	public var layInFront:Array<Array<FlxSprite>> = [[], [], []]; // BG layering, format: first [0] - in front of GF, second [1] - in front of opponent, third [2] - in front of boyfriend(and technically also opponent since Haxe layering moment)
	public var slowBacks:Map<Int,
		Array<FlxSprite>> = []; // Change/add/remove backgrounds mid song! Format: "slowBacks[StepToBeActivated] = [Sprites,To,Be,Changed,Or,Added];"

	var danceDir = false;

	// BGs still must be added by using toAdd Array for them to show in game after slowBacks take effect!!
	// BGs still must be added by using toAdd Array for them to show in game after slowBacks take effect!!
	// All of the above must be set or used in your stage case code block!!
	public var positions:Map<String, Map<String, Array<Float>>> = ['philly' => ['pico' => [100, 400]]];

	public function generateStageObject(stageData:StageData, stageObjects:Array<StageObject>, ?groupToAdd:FlxTypedGroup<FlxSprite>)
	{
		if (stageData.camZoom != null)
		{
			camZoom = stageData.camZoom;
		}

		if (!(curStage == "stage"))
		{
			if (!positions.exists(curStage))
			{
				var charPosMap = new Map<String, Array<Float>>();
				for (i in 0...stageData.characters.length)
				{
					var name = stageData.characters[i].name;
					var posX = stageData.characters[i].posX;
					var posY = stageData.characters[i].posY;
					charPosMap[name] = [posX, posY];
				}
				positions[curStage] = charPosMap;
			}
		}

		for (i in 0...stageObjects.length)
		{
			var obj = new FlxSprite(stageObjects[i].posX, stageObjects[i].posY);
			var anims:Array<ObjectAnim> = cast stageObjects[i].animations;

			var updateHitbox = stageObjects[i].updateHitbox == null ? false : stageObjects[i].updateHitbox;
			var scale = stageObjects[i].scale == null ? [] : stageObjects[i].scale;
			var scrollFactor = stageObjects[i].scrollFactor == null ? [] : stageObjects[i].scrollFactor;
			var visible = stageObjects[i].visible == null ? true : stageObjects[i].visible;
			var isDistraction = stageObjects[i].isDistraction == null ? false : stageObjects[i].isDistraction;
			var isMulti = stageObjects[i].isMulti == null ? false : stageObjects[i].isMulti;
			var isAnimated = stageObjects[i].isAnimated == null ? false : stageObjects[i].isAnimated;
			var isDancer = stageObjects[i].isDancer == null ? false : stageObjects[i].isDancer;
			var groupAdd = stageObjects[i].groupAdd == null ? false : stageObjects[i].groupAdd;
			var objSong = stageObjects[i].song == null ? "" : stageObjects[i].song;
			if (isMulti)
			{
				var group = new FlxTypedGroup<FlxSprite>();

				stageObjects[i].isMulti = false;
				var objData:Array<StageObject> = [];
				for (j in 0...stageObjects[i].multiNum)
				{
					var posX = cast stageObjects[i].posX + (stageObjects[i].multiDiff[0] * j);
					var posY = cast stageObjects[i].posY + (stageObjects[i].multiDiff[1] * j);
					var name = '${stageObjects[i].multiName}$j';
					var frames = stageObjects[i].frames;
					var startingAnim = stageObjects[i].startingAnim;
					var newObj:StageObject = {
						name: name,
						posX: posX,
						posY: posY,
						animations: anims,
						frames: frames,
						groupAdd: groupAdd,
						isDistraction: isDistraction,
						isDancer: isDancer,
						startingAnim: startingAnim,
						scrollFactor: scrollFactor
					};
					objData.push(newObj);
				}
				generateStageObject(stageData, objData, group);
				swagGroup['${stageObjects[i].name}'] = group;
				toAdd.push(group);
				continue;
			}

			if (!(anims == null))
			{
				obj.frames = Paths.getSparrowAtlas(stageObjects[i].frames[0], stageObjects[i].frames[1]);
				for (j in 0...anims.length)
				{
					var looped = anims[j].looped == null ? true : anims[j].looped;
					var fps = anims[j].fps == null ? 24 : anims[j].fps;
					var indices = anims[j].indices == null ? [] : anims[j].indices;
					var song = anims[j].song == null ? "" : anims[j].song;

					if (indices.length == 0)
					{
						if (song == "")
						{
							obj.animation.addByPrefix(anims[j].name, anims[j].prefix, fps, looped);
						}
						else
						{
							if (GameplayCustomizeState.freeplaySong == song)
							{
								obj.animation.addByPrefix(anims[j].name, anims[j].prefix, fps, looped);
							}
						}
					}
					else
					{
						if (song == "")
						{
							obj.animation.addByIndices(anims[j].name, anims[j].prefix, indices, "", fps, looped);
						}
						else
						{
							if (GameplayCustomizeState.freeplaySong == song)
							{
								obj.animation.addByIndices(anims[j].name, anims[j].prefix, indices, "", fps, looped);
							}
						}
					}
				}

				obj.animation.play(stageObjects[i].startingAnim);
			}
			else
			{ // jank. add failsafe later
				obj = new FlxSprite(stageObjects[i].posX,
					stageObjects[i].posY).loadGraphic(Paths.loadImage(stageObjects[i].frames[0], stageObjects[i].frames[1]));
				obj.active = stageObjects[i].active == null ? true : stageObjects[i].active;
			}

			if (!(scale.length == 0))
			{
				switch (scale.length)
				{
					case 1:
						{
							obj.setGraphicSize(Std.int(obj.width * scale[0]));
						}
					case 2:
						{
							obj.scale.set(scale[0], scale[1]);
						}
				}
			}

			if (!(scrollFactor.length == 0))
			{
				obj.scrollFactor.set(scrollFactor[0], scrollFactor[1]);
			}

			if (isAnimated)
			{
				animatedBacks.push(obj);
			}

			if (updateHitbox)
			{
				obj.updateHitbox();
			}

			obj.visible = visible;

			if (isDistraction)
			{
				if (objSong == "")
				{
					if (!(stageObjects[i].layInFront == null))
					{
						layInFront[stageObjects[i].layInFront].push(obj);
					}
					else if (groupAdd)
					{
						groupToAdd.add(obj);
					}
					else
					{
						toAdd.push(obj);
					}

					if (isDancer)
					{
						if (!swagGroup.exists("dancers"))
						{
							var group = new FlxTypedGroup<FlxSprite>();

							group.add(obj);
							swagGroup["dancers"] = group;
						}
						else
						{
							swagGroup["dancers"].add(obj);
						}
					}
					if (FlxG.save.data.distractions)
					{
						swagBacks['${stageObjects[i].name}'] = obj;
						continue;
					}
				}
				else
				{
					if (GameplayCustomizeState.freeplaySong == objSong)
					{
						if (!(stageObjects[i].layInFront == null))
						{
							layInFront[stageObjects[i].layInFront].push(obj);
						}
						else if (groupAdd)
						{
							groupToAdd.add(obj);
						}
						else
						{
							toAdd.push(obj);
						}

						if (isDancer)
						{
							if (!swagGroup.exists("dancers"))
							{
								var group = new FlxTypedGroup<FlxSprite>();

								group.add(obj);
								swagGroup["dancers"] = group;
							}
							else
							{
								swagGroup["dancers"].add(obj);
							}
						}
						if (FlxG.save.data.distractions)
						{
							swagBacks['${stageObjects[i].name}'] = obj;
							continue;
						}
					}
				}
			}
			else
			{
				if (objSong == "")
				{
					if (!(stageObjects[i].layInFront == null))
					{
						layInFront[stageObjects[i].layInFront].push(obj);
					}
					else if (groupAdd)
					{
						groupToAdd.add(obj);
					}
					else
					{
						toAdd.push(obj);
					}

					if (isDancer)
					{
						if (!swagGroup.exists("dancers"))
						{
							var group = new FlxTypedGroup<FlxSprite>();

							group.add(obj);
							swagGroup["dancers"] = group;
						}
						else
						{
							swagGroup["dancers"].add(obj);
						}
					}
					swagBacks['${stageObjects[i].name}'] = obj;
				}
				else
				{
					if (GameplayCustomizeState.freeplaySong == objSong)
					{
						if (!(stageObjects[i].layInFront == null))
						{
							layInFront[stageObjects[i].layInFront].push(obj);
						}
						else if (groupAdd)
						{
							groupToAdd.add(obj);
						}
						else
						{
							toAdd.push(obj);
						}

						if (isDancer)
						{
							if (!swagGroup.exists("dancers"))
							{
								var group = new FlxTypedGroup<FlxSprite>();

								group.add(obj);
								swagGroup["dancers"] = group;
							}
							else
							{
								swagGroup["dancers"].add(obj);
							}
						}
						swagBacks['${stageObjects[i].name}'] = obj;
					}
				}
			}
		}
	}

	public function new(daStage:String)
	{
		super();
		this.curStage = daStage;
		camZoom = 1.05; // Don't change zoom here, unless you want to change zoom of every stage that doesn't have custom one
		if (PlayStateChangeables.Optimize)
			return;

		if (Paths.doesTextAssetExist(Paths.json('stages/$curStage')))
		{
			var jsonData = Paths.loadJSON('stages/$curStage');
			var stageData:StageData = cast jsonData;

			var stageObjects:Array<StageObject> = cast stageData.objects;
			Debug.logInfo('Generating Stage: stages/$curStage');

			generateStageObject(stageData, stageObjects);
			return;
		}

		switch (daStage)
		{
			case 'philly':
				{
					var bg:FlxSprite = new FlxSprite(-100).loadGraphic(Paths.loadImage('philly/sky', 'week3'));
					bg.scrollFactor.set(0.1, 0.1);
					bg.antialiasing = FlxG.save.data.antialiasing;
					swagBacks['bg'] = bg;
					toAdd.push(bg);

					var city:FlxSprite = new FlxSprite(-10).loadGraphic(Paths.loadImage('philly/city', 'week3'));
					city.scrollFactor.set(0.3, 0.3);
					city.setGraphicSize(Std.int(city.width * 0.85));
					city.updateHitbox();
					city.antialiasing = FlxG.save.data.antialiasing;
					swagBacks['city'] = city;
					toAdd.push(city);

					var phillyCityLights = new FlxTypedGroup<FlxSprite>();
					if (FlxG.save.data.distractions)
					{
						swagGroup['phillyCityLights'] = phillyCityLights;
						toAdd.push(phillyCityLights);
					}

					for (i in 0...5)
					{
						var light:FlxSprite = new FlxSprite(city.x).loadGraphic(Paths.loadImage('philly/win' + i, 'week3'));
						light.scrollFactor.set(0.3, 0.3);
						light.visible = false;
						light.setGraphicSize(Std.int(light.width * 0.85));
						light.updateHitbox();
						light.antialiasing = FlxG.save.data.antialiasing;
						phillyCityLights.add(light);
					}

					var streetBehind:FlxSprite = new FlxSprite(-40, 50).loadGraphic(Paths.loadImage('philly/behindTrain', 'week3'));
					streetBehind.antialiasing = FlxG.save.data.antialiasing;
					swagBacks['streetBehind'] = streetBehind;
					toAdd.push(streetBehind);

					var phillyTrain = new FlxSprite(2000, 360).loadGraphic(Paths.loadImage('philly/train', 'week3'));
					phillyTrain.antialiasing = FlxG.save.data.antialiasing;
					if (FlxG.save.data.distractions)
					{
						swagBacks['phillyTrain'] = phillyTrain;
						toAdd.push(phillyTrain);
					}

					trainSound = new FlxSound().loadEmbedded(Paths.sound('train_passes', 'shared'));
					FlxG.sound.list.add(trainSound);

					// var cityLights:FlxSprite = new FlxSprite().loadGraphic(AssetPaths.win0.png);

					var street:FlxSprite = new FlxSprite(-40, streetBehind.y).loadGraphic(Paths.loadImage('philly/street', 'week3'));
					street.antialiasing = FlxG.save.data.antialiasing;
					swagBacks['street'] = street;
					toAdd.push(street);
				}
			default:
				{
					camZoom = 0.9;
					curStage = 'stage';
					var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic(Paths.loadImage('stageback', 'shared'));
					bg.antialiasing = FlxG.save.data.antialiasing;
					bg.scrollFactor.set(0.9, 0.9);
					bg.active = false;
					swagBacks['bg'] = bg;
					toAdd.push(bg);

					var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic(Paths.loadImage('stagefront', 'shared'));
					stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
					stageFront.updateHitbox();
					stageFront.antialiasing = FlxG.save.data.antialiasing;
					stageFront.scrollFactor.set(0.9, 0.9);
					stageFront.active = false;
					swagBacks['stageFront'] = stageFront;
					toAdd.push(stageFront);

					var stageCurtains:FlxSprite = new FlxSprite(-500, -300).loadGraphic(Paths.loadImage('stagecurtains', 'shared'));
					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
					stageCurtains.updateHitbox();
					stageCurtains.antialiasing = FlxG.save.data.antialiasing;
					stageCurtains.scrollFactor.set(1.3, 1.3);
					stageCurtains.active = false;

					swagBacks['stageCurtains'] = stageCurtains;
					toAdd.push(stageCurtains);
				}
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!PlayStateChangeables.Optimize)
		{
			switch (curStage)
			{
				case 'philly':
					if (trainMoving)
					{
						trainFrameTiming += elapsed;

						if (trainFrameTiming >= 1 / 24)
						{
							updateTrainPos();
							trainFrameTiming = 0;
						}
					}
					// phillyCityLights.members[curLight].alpha -= (Conductor.crochet / 1000) * FlxG.elapsed;
			}
		}
	}

	override function stepHit()
	{
		super.stepHit();

		if (!PlayStateChangeables.Optimize)
		{
			var array = slowBacks[curStep];
			if (array != null && array.length > 0)
			{
				if (hideLastBG)
				{
					for (bg in swagBacks)
					{
						if (!array.contains(bg))
						{
							var tween = FlxTween.tween(bg, {alpha: 0}, tweenDuration, {
								onComplete: function(tween:FlxTween):Void
								{
									bg.visible = false;
								}
							});
						}
					}
					for (bg in array)
					{
						bg.visible = true;
						FlxTween.tween(bg, {alpha: 1}, tweenDuration);
					}
				}
				else
				{
					for (bg in array)
						bg.visible = !bg.visible;
				}
			}
		}
	}

	override function beatHit()
	{
		super.beatHit();

		if (FlxG.save.data.distractions && animatedBacks.length > 0)
		{
			for (bg in animatedBacks)
				bg.animation.play('idle', true);
		}

		if (!PlayStateChangeables.Optimize)
		{
			switch (curStage)
			{
				case 'halloween':
					if (FlxG.random.bool(Conductor.bpm > 320 ? 100 : 10) && curBeat > lightningStrikeBeat + lightningOffset)
					{
						if (FlxG.save.data.distractions)
						{
							lightningStrikeShit();
							trace('spooky');
						}
					}
				case 'limo':
					if (FlxG.save.data.distractions)
					{
						if (FlxG.random.bool(10) && fastCarCanDrive)
							fastCarDrive();
					}
				case "philly":
					if (FlxG.save.data.distractions)
					{
						if (!trainMoving)
							trainCooldown += 1;

						if (curBeat % 4 == 0)
						{
							var phillyCityLights = swagGroup['phillyCityLights'];
							phillyCityLights.forEach(function(light:FlxSprite)
							{
								light.visible = false;
							});

							curLight = FlxG.random.int(0, phillyCityLights.length - 1);

							phillyCityLights.members[curLight].visible = true;
							// phillyCityLights.members[curLight].alpha = 1;
						}
					}

					if (curBeat % 8 == 4 && FlxG.random.bool(Conductor.bpm > 320 ? 150 : 30) && !trainMoving && trainCooldown > 8)
					{
						if (FlxG.save.data.distractions)
						{
							trainCooldown = FlxG.random.int(-4, 0);
							trainStart();
							trace('train');
						}
					}
			}

			if (FlxG.save.data.distractions)
			{
				dance(!danceDir);

				if (swagGroup.exists("dancers"))
				{
					swagGroup['dancers'].forEach(function(dancer:FlxSprite)
					{
						if (danceDir)
						{
							dancer.animation.play('danceRight', true);
						}
						else
						{
							dancer.animation.play('danceLeft', true);
						}
					});
				}
			}
		}
	}

	// Variables and Functions for Stages
	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;
	var curLight:Int = 0;

	function lightningStrikeShit():Void
	{
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2, 'shared'));
		swagBacks['halloweenBG'].animation.play('lightning');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		if (PlayState.boyfriend != null)
		{
			PlayState.boyfriend.playAnim('scared', true);
			PlayState.gf.playAnim('scared', true);
		}
		else
		{
			GameplayCustomizeState.boyfriend.playAnim('scared', true);
			GameplayCustomizeState.gf.playAnim('scared', true);
		}
	}

	public function dance(bool:Bool)
	{
		danceDir = bool;
	}

	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;

	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;
	var trainSound:FlxSound;

	function trainStart():Void
	{
		if (FlxG.save.data.distractions)
		{
			trainMoving = true;
			trainSound.play(true);
		}
	}

	var startedMoving:Bool = false;

	function updateTrainPos():Void
	{
		if (FlxG.save.data.distractions)
		{
			if (trainSound.time >= 4700)
			{
				startedMoving = true;

				if (PlayState.gf != null)
					PlayState.gf.playAnim('hairBlow');
				else
					GameplayCustomizeState.gf.playAnim('hairBlow');
			}

			if (startedMoving)
			{
				var phillyTrain = swagBacks['phillyTrain'];
				phillyTrain.x -= 400;

				if (phillyTrain.x < -2000 && !trainFinishing)
				{
					phillyTrain.x = -1150;
					trainCars -= 1;

					if (trainCars <= 0)
						trainFinishing = true;
				}

				if (phillyTrain.x < -4000 && trainFinishing)
					trainReset();
			}
		}
	}

	function trainReset():Void
	{
		if (FlxG.save.data.distractions)
		{
			if (PlayState.gf != null)
				PlayState.gf.playAnim('hairFall');
			else
				GameplayCustomizeState.gf.playAnim('hairFall');

			swagBacks['phillyTrain'].x = FlxG.width + 200;
			trainMoving = false;
			// trainSound.stop();
			// trainSound.time = 0;
			trainCars = 8;
			trainFinishing = false;
			startedMoving = false;
		}
	}

	var fastCarCanDrive:Bool = true;

	function resetFastCar():Void
	{
		if (FlxG.save.data.distractions)
		{
			var fastCar = swagBacks['fastCar'];
			fastCar.x = -12600;
			fastCar.y = FlxG.random.int(140, 250);
			fastCar.velocity.x = 0;
			fastCar.visible = false;
			fastCarCanDrive = true;
		}
	}

	function resetMoveObj(posX:Int, posY:Array<Int>):Void
	{
		if (FlxG.save.data.distractions)
		{
			var fastCar = swagBacks['fastCar'];
			fastCar.x = posX;
			fastCar.y = FlxG.random.int(posY[0], posY[1]);
			fastCar.velocity.x = 0;
			fastCar.visible = !(fastCar.visible);
			fastCarCanDrive = true;
		}
	}

	function fastCarDrive()
	{
		if (FlxG.save.data.distractions)
		{
			FlxG.sound.play(Paths.soundRandom('carPass', 0, 1, 'shared'), 0.7);

			swagBacks['fastCar'].visible = true;
			swagBacks['fastCar'].velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
			fastCarCanDrive = false;
			new FlxTimer().start(2, function(tmr:FlxTimer)
			{
				resetFastCar();
			});
		}
	}
}
