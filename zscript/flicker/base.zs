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
			return 0;
		}
		else
		{
			return super.DamageMobj(inflictor, source, damage, type, flags, angle);
		}
	}
}