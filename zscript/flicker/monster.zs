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

class FlickerAIHunger : Actor
{
	Default
	{
		+BRIGHT;
	}
	States
	{
		Spawn:
			HUNG A 0;
			HUNG A 1;
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

class FlickerPathNode : LightSensitive
{
	//SPECIAL THANKS TO: Ugly As Sin
	//For an example of how to do path nodes, and how to set a sprite index.
	Default
	{
		+NOINTERACTION;
		+FLATSPRITE;
		Radius 1;
		Height 1;
		Health 0;
	}
	States
	{
		Spawn:
			TNT1 A 0 NoDelay
			{
				if(Cvar.GetCvar("debug").GetBool())
				{
					sprite = GetSpriteIndex("FEAR");
				}
			}
		Exist:
			"####" A 350;
		Death:
			TNT1 A 0;
			Stop;
	}
	
}

class FlickerMonster : LightSensitive
{
	//Hunger and Fear values
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
	int fearThreshold; //used to track if fear went over minimum
	Property Hunger: hunger, hungerTickRate;
	// Starting hunger, number of tics to increase hunger at
	Property Fear: fear, fearTickRate;
	// Starting fear, number of tics to decrease fear at
	Property HungerLimits: hungerMin, hungerMax;
	Property FearLimits: fearMin, fearMax;
	// Minimum and Maximum for hunger and fear.
	//Fear should not decrease below a certain level after it's risen above that point.
	
	Actor oldTarget; //for storing the old target and switching back to it.
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
		FlickerMonster.Hunger 0, 350;
		FlickerMonster.HungerLimits 0, 256;
		FlickerMonster.Fear 0, 105;
		FlickerMonster.FearLimits 80, 256;
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
		//Same, but for removing fear. Also respects fear threshold.
		if(fearThreshold > fearMin)
		{
			self.fear = max(fearMin, self.fear-removed);
		}
		else
		{
			self.fear = max(0, self.fear-removed);
		}
	}
	
	Override Void Tick()
	{
		Super.Tick();
		CVar debugFlag = CVar.GetCVar("debug");
		
		//LightCoef becomes either an alpha value based on current light, or 0 at random
		Float LightCoef = max((GetLight()/256.0)-0.20,0);
		if(Random(1,GetLight())<64)
		{
			LightCoef = 0.0;
		}
		if(debugFlag.getBool())
		{
			A_SetRenderStyle(1,STYLE_Translucent);
		}
		else
		{
			A_SetRenderStyle(LightCoef, STYLE_Translucent);
		}
		
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
			fearThreshold = max(fearThreshold,fear);
			RemFear(1);
			fearTime = fearTime % fearTickRate;
			if(debugFlag.GetBool()){console.printf("New fear: %d",fear);}
		}
		
		// DEBUG FEATURES
		if(debugFlag.GetBool())
		{
			for(int i = 0; i < fear; i+=1)
			{
				A_SpawnProjectile("FlickerAIFear",random(32,64),random(-32,32),random(0,360));
			}
			for(int i = 0; i < hunger; i+=1)
			{
				A_SpawnProjectile("FlickerAIHunger",random(32,64),random(-32,32),random(0,360));
			}
			if(bFRIGHTENED)
			{
				A_SetTranslation("ice");
			}
			else
			{
				A_SetTranslation("");
			}
		}
	}
	
	States
	{
		Spawn:
			SARG ABCB 5 A_Look;
			Loop;
		Idle:
			SARG A 0
			{
				if(random(1,256)>fear-hunger)
				{
					bFRIGHTENED=false;
				}
				//A_Wander();
				if(random(1,512)<GetLight() && !(goal is "FlickerPathNode"))
				{
					return ResolveState("Search");
				}
				return ResolveState(null);
			}
			SARG ABCD 3 A_Chase;//A_Wander();
			Loop;
			
		Search:
			SARG A 1
			{
				//Clear old path nodes.
				A_KillChildren("none",0,"FlickerPathNode");
				let newTarget = FlickerPathNode(Spawn("FlickerPathNode",pos));
				oldTarget = target; // store old target for later
				bool isSeekingPlayer = random(1,256)<hunger-fear;
				for(int i = 0; i<8;i++)
				{
					Vector3 NewPos = Vec3Angle(512-GetLight(),i*45);
					let compareTarget = FlickerPathNode(Spawn("FlickerPathNode",pos+NewPos));
					if(isSeekingPlayer && compareTarget.Distance2D(oldTarget)>newTarget.Distance2D(oldTarget))
					{
						newTarget = compareTarget;
					}
					else if(compareTarget.GetLight()>newTarget.GetLight())
					{
						compareTarget.A_Die();
						newTarget = compareTarget;
					}
					
				}
				target = newTarget;
				goal = newTarget;
			}
			
		See:
			SARG A 0
			{
				if(CVar.GetCVar("debug").getBool()){console.printf("LOS: %d",CheckIfTargetInLOS());}
				if(!CheckIfTargetInLOS())
				{
					return ResolveState("Idle");
				}
				
				if(random(1,256)<hunger-fear-GetLight())
				{
					if(CheckProximity("PlayerPawn",60,1))
					{
						return ResolveState("Melee");
					}
					else
					{
						return ResolveState("Missile");
					}
				}
				if(random(1,256)<GetLight())
				{
					return ResolveState("Search");
				}
				return ResolveState("SeeConfirm");
			}
		SeeConfirm:
			SARG A 3
			{
				if(random(212,256)<fear-hunger+GetLight())
				{
					bFRIGHTENED=true;
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
				RemFear(random(1,3));
				if(random(1,256)>fear+hunger-GetLight())
				{
					bFRIGHTENED = false;
				}
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
				if(random(1,256)<fear-hunger+GetLight())
				{
					bFRIGHTENED=true;
				}
			}
			SARG H 5;
			Goto See;
			
	}
}