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
	Default
	{
		Monster;
		Health 500;
		Radius 20;
		Height 56;
		Speed 10;
		RenderStyle "Translucent";
	}
	
	Override Void Tick()
	{
		Super.Tick();
		/*If(GetLight()<64)
		{
			//self.RenderStyle = "None";
			A_SetRenderStyle(0.0,STYLE_OptFuzzy);
		}
		else if(GetLight()<192)
		{
			//self.RenderStyle = "OptFuzzy";
			A_SetRenderStyle(0.5,STYLE_OptFuzzy);
		}
		else
		{
			//self.RenderStyle = "Normal";
			A_SetRenderStyle(0.8,STYLE_OptFuzzy);
		}*/
		Float LightCoef = max((GetLight()/256.0)-0.20,0);
		if(Random(1,GetLight())<64)
		{
			LightCoef = 0.0;
		}
		//Console.printf("Light level %d, coefficient %f",GetLight(),LightCoef);
		A_SetRenderStyle(LightCoef, STYLE_Translucent);
	}
	
	States
	{
		Spawn:
			SARG ABCB 5 A_Look;
			Loop;
		See:
			SARG AB 3
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
	}
}