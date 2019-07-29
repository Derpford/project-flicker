Class FlareAmmo : Ammo
{
	//For flares.
	Default
	{
		Inventory.PickupMessage "You got a flare."; //Individual flares will actually be FlareWeapon.
		Inventory.Amount 1;
		Inventory.MaxAmount 16;
		Ammo.BackpackAmount 2;
		Ammo.BackpackMaxAmount 32;
	}
	States
	{
		Spawn:
			FLAR D -1;
			Stop;
	}
}
class FlareWeapon : Weapon
{
	//The actual flare pickup. Grants a Flare weapon that can toss flares.
	Default
	{
		Inventory.PickupMessage "You found a road flare.";
		Weapon.AmmoType "FlareAmmo";
		Weapon.SlotNumber 3;
		Weapon.AmmoGive 1;
	}
	States
	{
		Spawn:
			FLAR D 1;
			Loop;
		Select:
			FLWP A 1 A_Raise;
			Loop;
		Deselect:
			FLWP A 1 A_Lower;
			Loop;
		Ready:
			FLWP A 1 A_WeaponReady;
			Loop;
		Fire:
			PUNG ABCD 1;
			PUNG D 0 A_SpawnItemEX("FlareProjectile",4,0,32,12);
			FLWP A 1
			{
				A_TakeInventory("FlareAmmo",1);
				if(CountInv("FlareAmmo")<1)
				{
					A_SelectWeapon("Fist");
				}
			}
			Goto Ready;
	}
}

class FlareProjectile : Actor
{
	// The flare object in-game. I'll need to learn GLDEFS.
	int countdown;
	property Countdown: countdown;
	Default
	{
		//ReactionTime 400; // We'll handle the burn-down with A_Countdown.
		// TODO: Change to its own property.
		FlareProjectile.Countdown 200;

	}

	states
	{
		Spawn:
			TNT1 A 0;
		FlareLoop:
			FLAR A 1
			{
				countdown -= 1;
				LightFunctions lf;
				lf.CastLight(self,128);
				//A_Explode(128,128,0,true,64,0,0,"","Light");
				//Console.printf("Flare countdown: "..countdown);
				//if(countdown<1)
				//{	return(ResolveState("Death")); }
				//else
				//{ return(ResolveState(1)); }
			}
			FLAR B 1
			{
				if(countdown<1)
				{
					return (ResolveState("Death"));
				}
				else
				{
					return (ResolveState("FlareLoopEnd"));
				}
			}
			Loop;
		FlareLoopEnd:
			FLAR B 1;
			Goto FlareLoop;
		Death:
			FLAR E -1;
			Stop;
	}
}