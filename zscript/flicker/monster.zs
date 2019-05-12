class FlickerAIFear : Actor
{
	Default
	{
		+BRIGHT;
	}
	States
	{
		Spawn:
			FEAR A 0;
			FEAR A 1;
			Stop;
	}
}
class FlickerFake : LightSensitive
{
	Default
	{
		RenderStyle "Translucent";
		Alpha 0.8;
	}
	States
	{
		Spawn:
			TNT1 A 0;
			TNT1 A 0 
			{
			Float LightCoef = max((GetLight()/256.0)-0.20,0);
			//Console.printf("Light level %d, coefficient %f",GetLight(),LightCoef);
			A_SetRenderStyle(LightCoef, STYLE_Translucent);
			}
			TNT1 A 0 A_Jump(256,Random(1,4));
			SARG A 3;
			//Stop;
			SARG B 3;
			//Stop;
			SARG C 3;
			//Stop;
			SARG D 3;
			Stop;
	}
}

class FlickerFakeShadow : FlickerFake
{
	Default
	{
		RenderStyle "Translucent";
		Alpha 0.2;
	}
	States
	{
		Spawn:
			TNT1 A 0 A_Jump(256,Random(1,4));
			SARG ABCD 3;
			Stop;
	}
}



class FlickerMonster : LightSensitive
{
	int hunger;
	int hungerTime;
	int hungerTickRate;
	int hungerMax;
	int hungerMin;
	int fear;
	int fearTime;
	int fearTickRate;
	int fearMax;
	int fearMin;
	Property Hunger: hunger, hungerTickRate;
	// Starting hunger, number of tics to increase hunger at
	Property Fear: fear, fearTickRate;
	// Starting fear, number of tics to decrease fear at
	Property HungerLimits: hungerMin, hungerMax;
	Property FearLimits: fearMin, fearMax;
	// Minimum and Maximum for hunger and fear.
	//Fear should not decrease below a certain level after it's risen above that point.
	Default
	{
		Monster;
		Health 500;
		Radius 20;
		Height 56;
		Speed 10;
		MeleeRange 60;
		RenderStyle "Translucent";
		PainChance 256;
		+SHADOW;
		FlickerMonster.Hunger 0, 2100;
		FlickerMonster.HungerLimits 0, 256;
		FlickerMonster.Fear 0, 210;
		FlickerMonster.FearLimits 0, 256;
	}
	
	void AddHunger(int added = 1)
	{
		//Add hunger without overflowing.
		self.hunger = min(hungerMax, self.hunger+added);
	}
	
	void RemHunger(int removed = 1)
	{
		//Same, but for removing hunger.
		self.hunger = max(hungerMin, self.hunger-removed);
	}
	
	void AddFear(int added = 1)
	{
		//Add fear without overflowing.
		self.fear = min(fearMax, self.fear+added);
	}
	
	void RemFear(int removed = 1)
	{
		//Same, but for removing fear.
		self.fear = max(fearMin, self.fear-removed);
	}
	
	Override Void Tick()
	{
		Super.Tick();
		
		//LightCoef becomes either an alpha value based on current light, or 0 at random
		Float LightCoef = max((GetLight()/256.0)-0.20,0);
		if(Random(1,GetLight())<64)
		{
			LightCoef = 0.0;
		}
		A_SetRenderStyle(LightCoef, STYLE_Translucent);
		
		//Handle hunger and fear ticking. Hunger goes up over time and fear goes down.
		hungerTime += 1;
		if(hungerTime > hungerTickRate)
		{
			hunger += 1;
			hungerTime = hungerTime % hungerTickRate;
			hunger = min(hunger, hungerMax);
			hunger = max(hunger, hungerMin);
		}
		fearTime += 1;
		if(fearTime > fearTickRate)
		{
			fear -= 1;
			fearTime = fearTime % fearTickRate;
			fear = min(fear, fearMax);
			fear = max(fear, fearMin);
		}
		
		// DEBUG FEATURES
		CVar debugFlag = CVar.GetCVar("debug");
		if(debugFlag.GetBool())
		{
			for(int i = 0; i < fear; i+=1)
			{
				A_SpawnProjectile("FlickerAIFear",random(32,64),random(-32,32),random(0,360));
			}
		}
	}
	
	States
	{
		Spawn:
			SARG ABCB 5 A_Look;
			Loop;
		Idle:
			SARG A 3
			{
				if(random(1,256)<fear+hunger-GetLight())
				{
					A_ChangeFlag("FRIGHTENED",false);
				}
				//A_Wander();
				A_Chase(); //should continue fleeing, or seek the player if the monster is done being afraid
			}
			SARG BCD 3 A_Chase;//A_Wander();
			Loop;
		See:
			SARG A 0
			{
				if(!CheckIfTargetInLOS())
				{
					return ResolveState("Idle");
				}
				return ResolveState("SeeConfirm");
			}
		SeeConfirm:
			SARG A 3
			{
				if(random(1,256)>fear-hunger+GetLight())
				{
					A_ChangeFlag("FRIGHTENED",true);
				}
				A_Chase();
			}
			SARG B 3
			{
				if(GetLight()>80)
				{
					A_SpawnProjectile("FlickerFake",0,Random(-256+GetLight(),256-GetLight())/2,Random(0,360),CMF_AIMDIRECTION);
				}
				else
				{
					A_SpawnProjectile("FlickerFake",0,Random(-256+GetLight(),256-GetLight())/2,Random(0,360),CMF_AIMDIRECTION);
					A_SpawnProjectile("FlickerFakeShadow",0,Random(-256+GetLight(),256-GetLight())/2,Random(0,360),CMF_AIMDIRECTION);
				}
			}
			SARG CD 3 
			{
				A_Chase();
			}
			SARG A 0
			{
				if(GetLight()>80)
				{
					A_SpawnProjectile("FlickerFake",0,Random(-256+GetLight(),256-GetLight())/2,Random(0,360),CMF_AIMDIRECTION);
				}
				else
				{
					A_SpawnProjectile("FlickerFake",0,Random(-256+GetLight(),256-GetLight())/2,Random(0,360),CMF_AIMDIRECTION);
					A_SpawnProjectile("FlickerFakeShadow",0,Random(-256+GetLight(),256-GetLight())/2,Random(0,360),CMF_AIMDIRECTION);
				}
			}
			Goto See;
		Melee:
			SARG E 8 A_PlaySound("demon/melee");
			SARG EF 5 A_CustomMeleeAttack(Random(1,3)*10);
			SARG G 3
			{
				RemHunger(1);
				RemFear(1);
			}
			Goto See;
		Missile:
			SARG E 0 A_Jump(fear-hunger+GetLight(),"See");
		MissileConfirm:
			SARG E 5 A_SkullAttack(30);
			SARG F 1 A_JumpIfTargetInsideMeleeRange("Melee");
			//SARG F 0 A_Jump(fear-hunger+GetLight(),"See");
			Goto Missile;
			//SARG FG 3 A_CustomMeleeAttack(Random(1,3)*10);
			//Goto See;
		Pain:
			SARG G 5 
			{
				A_PlaySound("demon/pain");
				invoker.AddFear(Random(1,5));
			}
			SARG H 5;
			Goto See;
			
	}
}