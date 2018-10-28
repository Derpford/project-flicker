class LightSensitive : Actor
{
	// Light sensitive actor. Contains a Tick() function to handle sector light detection
	// and a special reaction to "Light" damage for giving dynlights an effect.
	int lightDynamic; // Light from "Light" damage.
	bool lightDynTicked; // Set when taking light damage.
											// If set, it's unset in Tick; if unset, lightDynamic is 0'd.

	int lightSector; // current sector light, checked every tick.

	override int DamageMobj(Actor inflictor, Actor source, int damage, name type, int flags, double angle)
	{
		// Handles "Light Damage", AKA what I'm attaching to dynlights to simulate detecting dynlight.
		if(type=="Light")
		{
			lightDynamic = damage;
			lightDynTicked = true;
			return 0;
		}
		else
		{
			return super.DamageMobj(inflictor, source, damage, type, flags, angle);
		}
	}

	override void Tick()
	{
		// Get the sector light and stick it in a handy variable every tick.
		//But first, make sure we aren't a voodoo doll. I don't use them but it's better to
		//be safe than sorry.
		if (!player || !player.mo || player.mo != self)
		{
			return Super.Tick();
		}

		lightSector = Sector.pointInSector(pos.xy).lightlevel; //Gutawer is the best.

		if(lightDynTicked)
		{
			lightDynTicked = false
		}
		else
		{
			//We didn't take light 'damage' this tic, so blank that variable out.
			lightDynamic = 0;
		}
	}

	int GetLight()
	{
		return lightSector+lightDynamic; // For convenience's sake.
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
					return state("HighLight");
				}
				else if(GetLight()>128)
				{
					return state("MidLight");
				}
				else
				{
					return state("LowLight");
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