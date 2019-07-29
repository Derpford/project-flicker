struct LightFunctions
{
	static play void CastLight(Actor caller, int radius)
	{
		BlockThingsIterator light = BlockThingsIterator.create(caller,radius);
		while (light.Next())
		{
			if(light.thing is "LightSensitive")
			{
				let LightThing = LightSensitive(light.thing);

				if(LightThing)
				{
					int lightAmount = floor(caller.Vec3To(LightThing).Length());
					LightThing.AddLight(LightAmount);
				}
			}

			if(light.thing is "FlickerMonster")
			{
				let LightThing = FlickerMonster(light.thing);

				if(LightThing)
				{
					LightThing.AddFear(); // Monster hates dynlights.
				}
			}
		}
	}
}

class LightSensitive : Actor
{
	// Light sensitive actor. Contains a Tick() function to handle sector light detection
	// and a special reaction to "Light" damage for giving dynlights an effect.
	int lightDynamic; // Light from "Light" damage.
	bool lightDynTicked; // Set when taking light damage.
											// If set, it's unset in Tick; if unset, lightDynamic is 0'd.
	int prevLightDynamic;
	int prevLightSector; // These store the previous light states.

	int lightSector; // current sector light, checked every tick.

	/*override int DamageMobj(Actor inflictor, Actor source, int damage, name type, int flags, double angle)
	{
		// Handles "Light Damage", AKA what I'm attaching to dynlights to simulate detecting dynlight.
		if(type=="Light")
		{
			lightDynamic += damage;
			lightDynTicked = true;
			return 0;
		}
		else
		{
			return super.DamageMobj(inflictor, source, damage, type, flags, angle);
		}
	}*/
	// Deprecated after I found out that BlockThingIterator can do this.

	override void Tick()
	{
		// Get all our light values in order, and apply fear.

		prevLightSector = lightSector;
		prevLightDynamic = lightDynamic;


		lightSector = Sector.pointInSector(pos.xy).lightlevel; //Gutawer is the best.

		if(lightDynTicked)
		{
			lightDynTicked = false;
		}
		else
		{
			//We didn't take light 'damage' this tic, so blank that variable out.
			lightDynamic = 0;
		}

		super.Tick();
	}

	int GetLight()
	{
		return lightSector+lightDynamic; // For convenience's sake.
	}

	void AddLight(int amt)
	{
		LightDynTicked = true;
		lightDynamic += amt; // For other things to add light.
	}

	States
	{
		// Debug actor; changes color based on current light.
		Spawn:
			TNT1 A 0;
			TNT1 A 0
			{
				if(GetLight()>256)
				{
					return A_Jump(256,"HighLight");
				}
				else if(GetLight()>128)
				{
					return A_Jump(256,"MidLight");
				}
				else
				{
					return A_Jump(256,"LowLight");
				}
			}
		HighLight:
			TFOG A 1;
			Goto Spawn;
		MidLight:
			PLSS A 1;
			Goto Spawn;
		LowLight:
			FIRE A 1;
			Goto Spawn;
	}
}

class LightPuff : BulletPuff
{
	// Exists to have the Light damagetype and to not show up.
	Default
	{
		+PUFFONACTORS;
		DamageType "Light";
	}
	states
	{
		Spawn:
		Death:
		XDeath:
		Crash:
		Melee:
			TNT1 A 0;
	}
}
