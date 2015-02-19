library AdaptiveMultiboard uses TimerUtils, MultiboardTools, OrderEvent, TeamIndexer, ReviveEvent optional MultiboardUnitsIcons, MultiboardItemsIcons/*
*********************************************************************************
*   AdaptiveMultiboard v1.1.2.2
*   ___________________________
*   by Thelordmarshall
*
*
*   I made this system inspired from dota multiboard with the feature that 
*   this may be adapted to any map with any number of teams, from here the name of
*   the system.
*
*   Notes: 
*   ______
*
*       - In order that it work correctly go to: Scenario/Player Properties/Forces
*           and select the box "Allied" of each force of your map.
*       - Do no call any of the api methods before the multiboard init, by default 
*           is at 0.02 seconds of game time.
*
*   Pros:
*   _____
*
*       - Designed for any map, perfect for you.
*       - The multiboard is refresh in a separated methods, this prevent the short 
*           period of lag caused for update all board data at the same time.
*       - The teams can see your private data: gold and lumber.
*       - No have empty slots.
*
*   API:
*   ____
*
*   struct AdvBoard:
*       - static method changeTitle takes string title returns nothing
*           - Change the current title to multiboard.
*       - static method setTeamName takes integer teamId, string name returns nothing
*           - Change team name.
*       - static method syncUnit takes unit whichUnit returns nothing
*           - Synchronize unit to multiboard.
*       - static method startCooldown takes integer cooldown, player whichPlayer returns nothing
*           - Start the cooldown (used when a unit/hero dies).
*       - static method show takes boolean show returns nothing
*           - Show/hide multiboard.
*
*   Credits:
*   ________
*
*       - Bribe: OrderEvent.
*       - Vexorian: TimerUtils.
*       - Magtheridon96: I take a just explaple for your Combat Multiboard System.
*
*   Copyright © 2015.
*********************************************************************************/

    //CONFIGURATION
    //============================================================================
    globals
        //Names and titles:
        private constant string     BOARD_TITLE         = "AdaptiveMultiboard v1.2"
        private constant string     DEFAULT_TEAM_NAME   = "Team"
        private constant string     COOLDOWN_NAME       = "CD"
        private constant string     LEVEL_NAME          = "Lvl"
        private constant string     KILL_NAME           = "K"
        private constant string     DEATH_NAME          = "D"
        //Colors:
        private constant string     DEFAULT_TEAM_COLOR  = "|c0000FF00"
        private constant string     EMPTY_COLOR         = "|cff080808"
        private constant string     KILL_DEATH_COLOR    = "|cffaaaaaa"
        private constant string     CD_COLOR            = "|c008A8B8C"
        private constant string     LVL_COLOR           = "|c00757677"
        private constant string     KILL_COLOR          = "|c008000FF"
        private constant string     DEATH_COLOR         = "|c00F43535"
        private constant string     GOLD_COLOR          = "|cffffcc00"
        private constant string     LUMBER_COLOR        = "|c00006C00"
        private constant string     FOOD_COLOR          = "|c00FF8000"
        private constant string     ITEM_COLOR          = "|c008000FF"
        //Icons:
        private constant string     DEFAULT_ICON        = "UI\\Widgets\\Console\\Undead\\undead-inventory-slotfiller.blp"
        private constant string     GOLD_ICON           = "UI\\Feedback\\Resources\\ResourceGold.blp"
        private constant string     LUMBER_ICON         = "UI\\Feedback\\Resources\\ResourceLumber.blp"
        private constant string     FOOD_ICON           = "UI\\Feedback\\Resources\\ResourceSupply.blp"
        //Advance configuration:
        private constant boolean    USE_GOLD            = true
        private constant boolean    USE_LUMBER          = true
        private constant boolean    USE_FOOD            = true
        private constant boolean    USE_ITEMS           = true
        private constant real       MULTIBOARD_INIT     = 0.02
    endglobals
    //Players colors:
    private function ConfigPlayersColors takes nothing returns nothing
        set playerColor[0] =  "|cffff0303"
        set playerColor[1] =  "|cff0042ff"
        set playerColor[2] =  "|cff1ce6b9" 
        set playerColor[3] =  "|cff540081"
        set playerColor[4] =  "|cfffffc01"
        set playerColor[5] =  "|cfffeba0e"
        set playerColor[6] =  "|cff20c000"
        set playerColor[7] =  "|cffe55bb0"
        set playerColor[8] =  "|cff959697"
        set playerColor[9] =  "|cff7ebff1"
        set playerColor[10] = "|cff106246"
        set playerColor[11] = "|cff4e2a04"
    endfunction
    //============================================================================
    //ENDCONFIGURATION
    
    globals
        string array playerColor
    endglobals
    
    //Textmacros:
    //! textmacro MultiboardGetState takes METHOD,STATE
        private static method $METHOD$ takes player p returns integer
            return GetPlayerState(p,PLAYER_STATE_RESOURCE_$STATE$)
        endmethod
    //! endtextmacro
    
    //! textmacro MultiboardSetItemValue takes METHOD_NAME,FUNCTION_NAME
        private static method $METHOD_NAME$ takes integer r, integer c, string s returns nothing
            local thistype i=0
            loop
                exitwhen i==bj_MAX_PLAYERS
                if .isPlaying(Player(i)) then
                    call i.mb.$FUNCTION_NAME$(r,c,s)
                endif
                set i=i+1
            endloop
        endmethod
    //! endtextmacro
        
    //! textmacro MultiboardUpdateResources takes METHOD,RESOURCE,INT_COLUMN
        private static method $METHOD$ takes nothing returns boolean
            local player p=GetTriggerPlayer()
            local integer r=GetPlayerState(p,PLAYER_STATE_RESOURCE_$RESOURCE$)
            call thistype(GetPlayerId(p)).updateResource($INT_COLUMN$,$RESOURCE$_COLOR+I2S(r)+"|r")
            return false
        endmethod
    //! endtextmacro
    
    //! textmacro MultiboardPlayerUnitEvent takes EVENT_NAME,METHOD_NAME
        set i=0
        set t=CreateTrigger()
        loop
            exitwhen i==bj_MAX_PLAYERS
            call TriggerRegisterPlayerUnitEvent(t,Player(i),EVENT_PLAYER_$EVENT_NAME$,null)
            set i=i+1
        endloop
        call TriggerAddCondition(t,function thistype.$METHOD_NAME$)
    //! endtextmacro
    
    //! textmacro MultiboardStateResource takes STATIC,USE_STATIC,STATE,METHOD
        $USE_STATIC$static if not $STATIC$ then
            $USE_STATIC$set COLUMN_COUNT=COLUMN_COUNT-1
        $USE_STATIC$else
            set i=0
            set t=CreateTrigger()
            loop
                exitwhen i==bj_MAX_PLAYERS
                set p=Player(i)
                set r=GetPlayerState(p,PLAYER_STATE_RESOURCE_$STATE$)
                call TriggerRegisterPlayerStateEvent(t,p,PLAYER_STATE_RESOURCE_$STATE$,GREATER_THAN,r)
                call TriggerRegisterPlayerStateEvent(t,p,PLAYER_STATE_RESOURCE_$STATE$,LESS_THAN,r)
                set i=i+1
            endloop
            call TriggerAddCondition(t,function thistype.$METHOD$)
        $USE_STATIC$endif
    //! endtextmacro
    
    //System core:
    struct AdvBoard
        private static integer COLUMN_COUNT=14 //Not Configurable.
        private static string mbTitle
        private Multiboard mb
        private unit boardHero
        private real cooldown
        private integer level
        private integer kill
        private integer death
        private integer teamKills
        private integer teamDeaths
        private integer teamIndex
        
        private static method isPlaying takes player p returns boolean
            return GetPlayerSlotState(p)==PLAYER_SLOT_STATE_PLAYING
        endmethod
        
        private static method isLeft takes player p returns boolean
            return GetPlayerSlotState(p)==PLAYER_SLOT_STATE_LEFT
        endmethod
        
        //! runtextmacro MultiboardGetState("getGold","GOLD")
        //! runtextmacro MultiboardGetState("getLumber","LUMBER")
        //! runtextmacro MultiboardGetState("getFoodUsed","FOOD_USED")
        //! runtextmacro MultiboardGetState("getFoodCap","FOOD_CAP")
        
        private method updateResource takes integer column, string r returns nothing
            local player p1=Player(this)
            local thistype i=0
            local integer row=2+GetPlayerForceId(p1)+GetPlayerIdInForce(p1)
            local player p
            loop
                exitwhen i==bj_MAX_PLAYERS
                set p=Player(i)
                if i.isPlaying(p) then
                    if IsPlayerAlly(p,p1) then
                        call i.mb.setText(row,column,r)
                    endif
                endif
                set i=i+1
            endloop
        endmethod
        
        //! runtextmacro MultiboardSetItemValue("changeText","setText")
        //! runtextmacro MultiboardSetItemValue("changeIcon","setIcon")
        
        static method show takes boolean show returns nothing
            local thistype i=0
            loop
                exitwhen i==bj_MAX_PLAYERS
                if show then
                    set i.mb.showPlayer=Player(i)
                else
                    set i.mb.show=false
                endif
                set i=i+1
            endloop
        endmethod
        
        static method changeTitle takes string title returns nothing
            local thistype i=0
            set mbTitle=title
            loop
                exitwhen i==bj_MAX_PLAYERS
                set i.mb.title=KILL_DEATH_COLOR+I2S(i.kill)+"/"+I2S(i.death)+"|r - "+mbTitle
                set i=i+1
            endloop
        endmethod
        
        static method setTeamName takes integer teamId, string name returns nothing
            if (teamId>=0 and teamId<=GetMapTeams()-1) then
                call .changeText(thistype(teamId).teamIndex,0,name)
            debug else
                debug call DisplayTimedTextToPlayer(GetLocalPlayer(),0.,0.,60.,"[AdaptiveMultiboard] Error: Team index "+I2S(teamId)+" does not exist.")
            endif
        endmethod
        
        static method syncUnit takes unit whichUnit returns nothing
            local player p=GetOwningPlayer(whichUnit)
            local thistype playerId=GetPlayerId(p)
            local integer row=2+GetPlayerForceId(p)+GetPlayerIdInForce(p)
            if (playerId>=0 and playerId<=11) then
                set playerId.boardHero=whichUnit
                call .changeIcon(row,0,GetUnitIcon(whichUnit))
                call .changeText(row,2,LVL_COLOR+I2S(GetUnitLevel(whichUnit))+"|r")
                call TimerStart(NewTimerEx(playerId),.001,false,function thistype.updateAllSlotsIcons)
            else
                debug call DisplayTimedTextToPlayer(GetLocalPlayer(),0.,0.,60.,"[AdaptiveMultiboard] Error: Player id "+I2S(playerId)+" does not exist.")
            endif
        endmethod
        
        private static method onCooldown takes nothing returns nothing
            local timer t=GetExpiredTimer()
            local thistype id=GetTimerData(t)
            local player p=Player(id)
            local integer row=2+GetPlayerForceId(p)+GetPlayerIdInForce(p)
            set id.cooldown=id.cooldown-.03125
            call .changeText(row,1,CD_COLOR+I2S(R2I(id.cooldown))+"|r")
            if id.cooldown<=1. then
                call .changeText(row,1,EMPTY_COLOR+I2S(R2I(id.cooldown))+"|r")
                call ReleaseTimer(t)
            endif
            set t=null
        endmethod
        
        static method startCooldown takes integer cooldown, player whichPlayer returns nothing
            local thistype this=GetPlayerId(whichPlayer)
            if (this>=0 and this<=11) then
                if .cooldown<=1. then
                    set .cooldown=I2R(cooldown)+1.
                    call TimerStart(NewTimerEx(this),.03125,true,function thistype.onCooldown)
                else
                    debug call DisplayTimedTextToPlayer(GetLocalPlayer(),0.,0.,60.,"[AdaptiveMultiboard] Error: Cooldown id "+I2S(this)+" is allready started.")
                endif
            else
                debug call DisplayTimedTextToPlayer(GetLocalPlayer(),0.,0.,60.,"[AdaptiveMultiboard] Error: Player id "+I2S(this)+" does not exist.")
            endif
        endmethod
        
        private method addPlayers takes nothing returns nothing
            local integer i=0
            local integer row
            local player p
            local string s
            loop
                exitwhen i==bj_MAX_PLAYERS
                set p=Player(i)
                set row=2+GetPlayerForceId(p)+GetPlayerIdInForce(p)
                if .isLeft(p) then
                    set s=EMPTY_COLOR+GetPlayerName(p)+"|r"
                endif
                if .isPlaying(p) then
                    set s=playerColor[i]+GetPlayerName(p)+"|r"
                    call .mb.setIcon(row,0,DEFAULT_ICON)
                    call .mb.setStyle(row,0,true,true)
                    call .mb.setText(row,0,s)
                    call .mb.setText(row,1,EMPTY_COLOR+I2S(R2I(.cooldown))+"|r")
                    call .mb.setText(row,2,EMPTY_COLOR+I2S(.level)+"|r")
                    call .mb.setText(row,3,KILL_COLOR+I2S(.kill)+"|r")
                    call .mb.setText(row,4,DEATH_COLOR+I2S(.death)+"|r")
                    if IsPlayerAlly(p,Player(this)) then
                        call .mb.setText(row,5,GOLD_COLOR+I2S(.getGold(p))+"|r")
                        call .mb.setText(row,6,LUMBER_COLOR+I2S(.getLumber(p))+"|r")
                        call .mb.setText(row,7,FOOD_COLOR+I2S(.getFoodUsed(p))+"/"+I2S(.getFoodCap(p))+"|r")
                    endif
                endif
                set i=i+1
            endloop
        endmethod

        private method initForPlayer takes nothing returns nothing
            local integer forceCount=GetMapTeams()
            local integer countP=0
            local integer row=1
            local thistype h=0
            set .mb=Multiboard.create(KILL_DEATH_COLOR+"0"+"/"+"0"+"|r - "+mbTitle,1+forceCount+GetCountPlayers(),COLUMN_COUNT)
            //Setting the multiboard.
            call .mb.setStyle(0,0,true,false)
            call .mb.setWidth(0,0,10.20)//Player name.
            call .mb.setWidth(0,1,1.80)//Cooldown.
            call .mb.setWidth(0,2,1.80)//Player hero level.
            call .mb.setWidth(0,3,1.30)//Player hero kills.
            call .mb.setWidth(0,4,1.30)//Player hero deaths.
            call .mb.setWidth(0,5,3.00)//Player gold.
            call .mb.setWidth(0,6,3.00)//Player lumber.
            call .mb.setWidth(0,7,2.80)//Player food.
            call .mb.setWidth(0,8,1.10)//Items slots start.
            call .mb.setWidth(0,9,1.10)
            call .mb.setWidth(0,10,1.10)
            call .mb.setWidth(0,11,1.10)
            call .mb.setWidth(0,12,1.10)
            call .mb.setWidth(0,13,1.10)//Items slots end.
            //Teams/players data.
            call .mb.setText(0,1,COOLDOWN_NAME)
            call .mb.setText(0,2,LVL_COLOR+LEVEL_NAME+"|r")
            call .mb.setText(0,3,KILL_COLOR+KILL_NAME+"|r")
            call .mb.setText(0,4,DEATH_COLOR+DEATH_NAME+"|r")
            call .mb.setIcon(0,5,GOLD_ICON)
            call .mb.setIcon(0,6,LUMBER_ICON)
            call .mb.setIcon(0,7,FOOD_ICON)
            call .mb.setText(0,9,ITEM_COLOR+"  it"+"|r")
            call .mb.setText(0,10,ITEM_COLOR+"em"+"|r")
            call .mb.setText(0,11,ITEM_COLOR+" s"+"|r")
            //Adding Teams.
            loop
                exitwhen h==forceCount
                if h!=0 then
                    set countP=countP+CountPlayersInForce(h-1)
                    set row=1+countP+h
                endif
                set h.teamIndex=row
                call .mb.setText(row,0,DEFAULT_TEAM_COLOR+DEFAULT_TEAM_NAME+" "+I2S(h+1)+"|r")
                call .mb.setText(row,3,KILL_COLOR+"0|r")
                call .mb.setText(row,4,DEATH_COLOR+"0|r")
                set h=h+1
            endloop
            //Adding players.
            call .addPlayers()
            set .mb.show=false
        endmethod 
        
        //! runtextmacro MultiboardUpdateResources("updateGold","GOLD","5")
        //! runtextmacro MultiboardUpdateResources("updateLumber","LUMBER","6")
        
        private static method updateFood takes nothing returns boolean
            local player p=GetTriggerPlayer()
            //local integer r1=.getFoodUsed(p)
            //local integer r2=.getFoodCap(p)
            call thistype(GetPlayerId(p)).updateResource(7,FOOD_COLOR+I2S(.getFoodUsed(p))+"/"+I2S(.getFoodCap(p))+"|r")
            return false
        endmethod
        
        private static method setFoodOnRevive takes nothing returns boolean
            local unit u=GetLastRevivedUnit()
            local player p=GetOwningPlayer(u)
            local thistype this=GetPlayerId(p)
            //local integer r1=.getFoodUsed(p)
            //local integer r2=.getFoodCap(p)
            if (GetUnitFoodUsed(u)>0 or GetUnitFoodMade(u)>0) then
                call .updateResource(7,FOOD_COLOR+I2S(.getFoodUsed(p))+"/"+I2S(.getFoodCap(p))+"|r")
            endif
            set u=null
            return false
        endmethod
        
        //Kills/deaths update.
        private static method updateKillsDeaths takes nothing returns boolean
            local unit deathUnit=GetDyingUnit()
            local unit killingUnit=GetKillingUnit()
            local player pl1=GetOwningPlayer(deathUnit)
            local player pl2=GetOwningPlayer(killingUnit)
            local thistype p1=GetPlayerId(pl1)
            local thistype p2=GetPlayerId(pl2)
            local thistype t1=GetPlayerForceId(pl1)
            local thistype t2=GetPlayerForceId(pl2)
            local integer row1=2+GetPlayerForceId(pl1)+GetPlayerIdInForce(pl1)
            local integer row2=2+GetPlayerForceId(pl2)+GetPlayerIdInForce(pl2)
            local thistype this=0
            if ((deathUnit==p1.boardHero and killingUnit==p2.boardHero) or (pl2==GetOwningPlayer(p2.boardHero) and IsUnitType(deathUnit,UNIT_TYPE_HERO))) and not IsPlayerAlly(pl1,pl2) then
                set p2.kill=p2.kill+1
                set t2.teamKills=t2.teamKills+1
                set p1.death=p1.death+1
                set t1.teamDeaths=t1.teamDeaths+1
                loop
                    exitwhen this==bj_MAX_PLAYERS
                    if .isPlaying(Player(this)) then
                        call .mb.setText(row2,3,KILL_COLOR+I2S(p2.kill)+"|r")
                        call .mb.setText(row1,4,DEATH_COLOR+I2S(p1.death)+"|r")
                    endif
                    call .mb.setText(t2.teamIndex,3,KILL_COLOR+I2S(t2.teamKills)+"|r")
                    call .mb.setText(t1.teamIndex,4,DEATH_COLOR+I2S(t1.teamDeaths)+"|r")
                    set this=this+1
                endloop
                set p2.mb.title=KILL_DEATH_COLOR+I2S(p2.kill)+"/"+I2S(p2.death)+"|r - "+mbTitle
                set p1.mb.title=KILL_DEATH_COLOR+I2S(p1.kill)+"/"+I2S(p1.death)+"|r - "+mbTitle
            endif
            set deathUnit=null
            set killingUnit=null
            return false
        endmethod
        
        //Levels update.
        private static method updateLevel takes nothing returns boolean
            local unit u=GetTriggerUnit()
            local player p=GetTriggerPlayer()
            local thistype i=GetPlayerId(p)
            local integer row=2+GetPlayerForceId(p)+GetPlayerIdInForce(p)
            if (u==i.boardHero and IsUnitType(u,UNIT_TYPE_HERO)) then
                set i.level=GetUnitLevel(u)
                call .changeText(row,2,LVL_COLOR+I2S(i.level)+"|r")
            endif
            set u=null
            return false
        endmethod
        
        private static method updateAllSlotsIcons takes nothing returns nothing
            local timer t=GetExpiredTimer()
            local thistype this=GetTimerData(t)
            local player p=Player(this)
            local integer row=2+GetPlayerForceId(p)+GetPlayerIdInForce(p)
            local integer i=0
            local item it
            loop
                set it=UnitItemInSlot(.boardHero,i)
                exitwhen i==6
                if it!=null then
                    call .changeIcon(row,8+i,GetItemIcon(UnitItemInSlot(.boardHero,i)))
                else
                    call .changeIcon(row,8+i,DEFAULT_ICON)
                endif
                set i=i+1
            endloop
            call ReleaseTimer(t)
            set t=null
        endmethod
        
        private static method updateSlots takes nothing returns boolean
            local unit u=GetTriggerUnit()
            local thistype id=GetPlayerId(GetOwningPlayer(u))
            if u==id.boardHero then
                call TimerStart(NewTimerEx(id),.001,false,function thistype.updateAllSlotsIcons)
            endif
            set u=null
            return false
        endmethod
        
        //Init items icons: I used this method detached from .initMultiboard because 
        //for some reason the multiboard is not complety created for all players when 
        //used many loops at same time.
        private static method initItemsIcons takes nothing returns nothing
            local thistype i=0
            local integer h=0
            local integer n=8
            local integer row
            local player p
            loop
                exitwhen i==bj_MAX_PLAYERS
                if .isPlaying(Player(i)) then
                    loop
                        exitwhen h==bj_MAX_PLAYERS
                        set p=Player(h)
                        set row=2+GetPlayerForceId(p)+GetPlayerIdInForce(p)
                        loop
                            exitwhen n==14
                            call i.mb.setIcon(row,n,DEFAULT_ICON)
                            call i.mb.setStyle(row,n,true,true)
                            set n=n+1
                        endloop
                        set n=8
                        set h=h+1
                    endloop
                    set h=0
                endif
                set i=i+1
            endloop
            call ReleaseTimer(GetExpiredTimer())
        endmethod
        
        //Init the multiboard for the 12 players.
        private static method initMultiboard takes nothing returns nothing
            local thistype i=0
            local integer n=7
            local integer row
            local player p
            set mbTitle=BOARD_TITLE
            loop
                exitwhen i==bj_MAX_PLAYERS
                set p=Player(i)
                if .isPlaying(p) then
                    call i.initForPlayer()
                endif
                set i=i+1
            endloop
            call ReleaseTimer(GetExpiredTimer())
        endmethod
        
        private static method onInit takes nothing returns nothing
            local integer i
            local trigger t
            local player p
            local integer r
            call ConfigPlayersColors()
            call TimerStart(NewTimer(),MULTIBOARD_INIT,false,function thistype.initMultiboard)
            //! runtextmacro MultiboardStateResource("USE_GOLD","","GOLD","updateGold")
            //! runtextmacro MultiboardStateResource("USE_LUMBER","","LUMBER","updateLumber")
            //! runtextmacro MultiboardStateResource("USE_FOOD","","FOOD_CAP","updateFood")
            //! runtextmacro MultiboardStateResource("USE_FOOD","//","FOOD_USED","updateFood")
            call ReviveRegisterEvent(Revive.EVENT_ANY_REVIVE,Condition(function thistype.setFoodOnRevive))
            static if not USE_ITEMS then
                set COLUMN_COUNT=COLUMN_COUNT-6
            else
                call TimerStart(NewTimer(),MULTIBOARD_INIT+.01,false,function thistype.initItemsIcons)
            endif
            //! runtextmacro MultiboardPlayerUnitEvent("UNIT_DEATH","updateKillsDeaths")
            //! runtextmacro MultiboardPlayerUnitEvent("HERO_LEVEL","updateLevel")
            //! runtextmacro MultiboardPlayerUnitEvent("UNIT_PICKUP_ITEM","updateSlots")
            //! runtextmacro MultiboardPlayerUnitEvent("UNIT_DROP_ITEM","updateSlots")
            set i=0
            loop
                exitwhen i==6
                call RegisterOrderEvent(852002+i,function thistype.updateSlots)
                set i=i+1
            endloop
        endmethod
    endstruct
endlibrary
