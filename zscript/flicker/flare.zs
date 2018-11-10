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
		Weapon.AmmoType "FlareAmmo";
		Weapon.SlotNumber 3;
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
			FLWP A 1;

	}
}