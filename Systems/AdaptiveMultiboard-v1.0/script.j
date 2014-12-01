library AdaptiveMultiboard uses Table, TimerUtils, TeamReforce, MultiboardUtils, GradientText, Hero
/*********************************************************************************
*   AdaptiveMultiboard v1.0.0.1
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
*   Cons:
*   _____
*
*       - The items featured no do work at the moment... I promise that I will finish 
*           it for the next version.
*
*   API:
*   ____
*
*   struct Multiboard:
*       - static method setTitle takes string title returns nothing
*           - Change the current title to all multiboards (12 players).
*       - static method setTeamName takes thistype teamIndex, string teamName returns nothing
*           - Change a team name.
*       - static method syncPlayerHero takes thistype playerId, unit whichHero returns nothing
*           - Synchronize a unit/hero to multiboard.
*       - static method startCooldown takes thistype playerId, integer cooldown returns nothing
*           - Start the cooldown when a unit/hero dies.
*       - static method show takes player whichPlayer returns nothing
*           - Show the multiboard for player.
*       - static method hide takes player whichPlayer returns nothing
*           - Hide for player.
*
*   Credits:
*   ________
*
*       - Bribe: Table.
*       - Vexorian: TimerUtils.
*       - Dalvengyr: GradientText.
*       - Magtheridon96: I take a just explaple for your Combat Multiboard System.
*
*   Copyright © 2014.
*********************************************************************************/

//CONFIGURATION:
    globals
        //Names and titles:
        private constant string     BOARD_TITLE         = "New AdaptiveMultiboard v1.0"
        private constant string     DEFAULT_TEAM_NAME   = "Team"
        private constant string     COOLDOWN_NAME       = "cd"
        private constant string     LEVEL_NAME          = "lvl"
        private constant string     KILL_NAME           = "k"
        private constant string     DEATH_NAME          = "d"
        //Colors:
        private constant string     EMPTY_COLOR         = "|cff080808"
        private constant string     KILL_DEATH_COLOR    = "|cffaaaaaa"
        private constant string     CD_COLOR            = "|c008A8B8C"
        private constant string     LVL_COLOR           = "|c00757677"
        private constant string     KILL_COLOR          = "|c008000FF"
        private constant string     DEATH_COLOR         = "|c00F43535"
        private constant string     GOLD_COLOR          = "|cffffcc00"
        private constant string     LUMBER_COLOR        = "|c00006C00" 
        private constant string     ITEM_COLOR          = "|c00FF8040"
        //Default Gradients Colors:
        private constant string     TITLE_COLOR_1       = "0xdae65b"
        private constant string     TITLE_COLOR_2       = "0x3e4e0e"
        private constant string     TEAM_COLOR_1        = "0x008080"
        private constant string     TEAM_COLOR_2        = "0x01fa30"
        //Icons:
        private constant string     DEFAULT_ICON        = "UI\\Widgets\\Console\\Undead\\undead-inventory-slotfiller.blp"
        private constant string     GOLD_ICON           = "UI\\Feedback\\Resources\\ResourceGold.blp"
        private constant string     LUMBER_ICON         = "UI\\Widgets\\ToolTips\\Human\\ToolTipLumberIcon.blp"
        //Advance configuration:
        private constant boolean    USE_GOLD            = true
        private constant boolean    USE_LUMBER          = true
        private constant boolean    USE_ITEMS           = false //Not available at the moment.
        private constant real       MULTIBOARD_INIT     = 0.02
    endglobals
        //Players colors:
    private function ConfigPlayersColors takes nothing returns nothing
        set PLAYER_COLOR[0] =  "|cffff0303"
        set PLAYER_COLOR[1] =  "|cff0042ff"
        set PLAYER_COLOR[2] =  "|cff1ce6b9" 
        set PLAYER_COLOR[3] =  "|cff540081"
        set PLAYER_COLOR[4] =  "|cfffffc01"
        set PLAYER_COLOR[5] =  "|cfffeba0e"
        set PLAYER_COLOR[6] =  "|cff20c000"
        set PLAYER_COLOR[7] =  "|cffe55bb0"
        set PLAYER_COLOR[8] =  "|cff959697"
        set PLAYER_COLOR[9] =  "|cff7ebff1"
        set PLAYER_COLOR[10] = "|cff106246"
        set PLAYER_COLOR[11] = "|cff4e2a04"
    endfunction
//ENDCONFIGURATION
    
    globals
        constant string array PLAYER_COLOR
    endglobals
    
    struct Multiboard
        //Please note: Not configurable.
        private static constant real REFRESH_PERIOD = 0.03125
        private static constant string CLOSE = "|r"
        private static integer COLUMN_COUNT  = 13
        private static Table mb
        private static string mbTitle
        //Multiboard data.
        private unit    boardHero
        private string  teamName
        private string  heroIcon
        private real    cooldown
        private integer level
        private integer kill
        private integer death
        private integer gold
        private integer lumber
        private integer teamKills
        private integer teamDeaths
        private integer teamIndex
        
        private static method updateMultiboard takes integer row, integer column, string value, boolean updateIcon returns nothing
            local thistype this = 0
            //I use textmacros to optimize the code.
            //! textmacro UpdateMultiboard takes USE_IF,USE_ELSE,USE_SECOND_IF,ROW,COLUMN,VALUE
            loop
                exitwhen this == bj_MAX_PLAYERS
                $USE_IF$if GetPlayerSlotState(Player(this)) == PLAYER_SLOT_STATE_PLAYING then
                    $USE_SECOND_IF$if not updateIcon then
                        call MbSetItemValue(mb.multiboard[this],$ROW$,$COLUMN$,$VALUE$)
                    $USE_ELSE$else
                        $USE_ELSE$call MbSetItemIcon(mb.multiboard[this],$ROW$,$COLUMN$,$VALUE$)
                    $USE_SECOND_IF$endif
                $USE_IF$endif
                set this = this+1
            endloop
            //! endtextmacro
            //! runtextmacro UpdateMultiboard("//","","","row","column","value")
        endmethod
        
        static method show takes player whichPlayer returns nothing
            if GetLocalPlayer() == whichPlayer then
                call MultiboardDisplay(mb.multiboard[GetPlayerId(whichPlayer)],true)
            endif
        endmethod
        
        static method hide takes player whichPlayer returns nothing
            if GetLocalPlayer() == whichPlayer then
                call MultiboardDisplay(mb.multiboard[GetPlayerId(whichPlayer)],false)
            endif
        endmethod
        
        static method setTitle takes string title returns nothing
            local integer this = 0
            set mbTitle = title
            loop
                exitwhen this == bj_MAX_PLAYERS
                call MultiboardSetTitleText(mb.multiboard[this],KILL_DEATH_COLOR+I2S(.kill)+"/"+I2S(.death)+"|r - "+GradientText(mbTitle))
                set this = this+1
            endloop
        endmethod
        
        static method setTeamName takes thistype teamIndex, string teamName returns nothing
            if teamIndex >= 0 and teamIndex <= GetMapTeams()-1 then
                call .updateMultiboard(teamIndex.teamIndex,0,GradientText(teamName),false)
            else
                debug call DisplayTimedTextToPlayer(GetLocalPlayer(),0.,0.,60.,"[AdaptiveMultiboard] Error: Team index "+I2S(teamIndex)+" does not exist.")
            endif
        endmethod
        
        static method syncPlayerHero takes thistype playerId, unit whichHero returns nothing
            local integer row   = 2+GetPlayerForceIndex(playerId)+GetPlayerIdInForce(playerId)
            local integer i     = 0
            local integer id    = GetUnitTypeId(whichHero)
            local player p      = Player(playerId)
            local thistype this = 0
            if playerId >= 0 and playerId <= 11 then
                if p == GetOwningPlayer(whichHero) then
                    set playerId.boardHero = whichHero
                    loop
                        exitwhen HERO[i] == id or HERO[i] == null
                        set i = i+1
                    endloop
                    call .updateMultiboard(row,0,HERO_ICON[i],true)
                    //! runtextmacro UpdateMultiboard("//","//","//","row","2","LVL_COLOR+I2S(GetUnitLevel(whichHero))+CLOSE")
                else
                    debug call DisplayTimedTextToPlayer(GetLocalPlayer(),0.,0.,60.,"[AdaptiveMultiboard] Error: "+GetPlayerName(p)+" is not owner of "+GetUnitName(whichHero)+".")
                endif
            else
                debug call DisplayTimedTextToPlayer(GetLocalPlayer(),0.,0.,60.,"[AdaptiveMultiboard] Error: Player id "+I2S(playerId)+" does not exist.")
            endif
        endmethod
        
        private static method onCooldown takes nothing returns nothing
            local timer t       = GetExpiredTimer()
            local thistype id   = GetTimerData(t)
            local thistype this = 0
            local integer row   = 2+GetPlayerForceIndex(id)+GetPlayerIdInForce(id)
            set id.cooldown = id.cooldown-REFRESH_PERIOD
            call .updateMultiboard(row,1,CD_COLOR+I2S(R2I(id.cooldown))+"|r",false)
            if id.cooldown <= 1. then
                //! runtextmacro UpdateMultiboard("//","//","//","row","1","EMPTY_COLOR+I2S(R2I(id.cooldown))+CLOSE")
                call ReleaseTimer(t)
            endif
            set t = null
        endmethod
        
        static method startCooldown takes thistype playerId, integer cooldown returns nothing
            if playerId >= 0 and playerId <= 11 then
                if playerId.cooldown <= 1. then
                    set playerId.cooldown = I2R(cooldown)+1.
                    call TimerStart(NewTimerEx(playerId),REFRESH_PERIOD,true,function thistype.onCooldown)
                else
                    debug call DisplayTimedTextToPlayer(GetLocalPlayer(),0.,0.,60.,"[AdaptiveMultiboard] Error: Cooldown id "+I2S(playerId)+" is allready started.")
                endif
            else
                debug call DisplayTimedTextToPlayer(GetLocalPlayer(),0.,0.,60.,"[AdaptiveMultiboard] Error: Player id "+I2S(playerId)+" does not exist.")
            endif
        endmethod
        
        private method addPlayers takes nothing returns nothing
            local integer i = 0
            local integer row
            local player p
            loop
                exitwhen i == bj_MAX_PLAYERS
                set p = Player(i)
                if GetPlayerSlotState(p) != PLAYER_SLOT_STATE_EMPTY then
                    set row = 2+GetPlayerForceIndex(i)+GetPlayerIdInForce(i)
                    if GetPlayerSlotState(p) == PLAYER_SLOT_STATE_LEFT then
                        //Again a textmacro.
                        //! textmacro PlayerData takes COLOR
                        call MbSetItemIcon (mb.multiboard[this],row,0,DEFAULT_ICON)
                        call MbSetItemStyle(mb.multiboard[this],row,0,true,true)
                        call MbSetItemValue(mb.multiboard[this],row,0,$COLOR$     +GetPlayerName(p)   +"|r")
                        call MbSetItemValue(mb.multiboard[this],row,1,EMPTY_COLOR +I2S(R2I(.cooldown))+"|r")
                        call MbSetItemValue(mb.multiboard[this],row,2,EMPTY_COLOR +I2S(.level)        +"|r")
                        call MbSetItemValue(mb.multiboard[this],row,3,KILL_COLOR  +I2S(.kill)         +"|r")
                        call MbSetItemValue(mb.multiboard[this],row,4,DEATH_COLOR +I2S(.death)        +"|r")
                        if IsPlayerAlly(p,Player(this)) then
                            call MbSetItemValue(mb.multiboard[this],row,5,GOLD_COLOR  +I2S(.gold)         +"|r")
                            call MbSetItemValue(mb.multiboard[this],row,6,LUMBER_COLOR+I2S(.lumber)       +"|r")
                        endif
                        //! endtextmacro
                        //! runtextmacro PlayerData("EMPTY_COLOR")
                    else
                        //! runtextmacro PlayerData("PLAYER_COLOR[i]")
                    endif
                endif
                set i = i+1
            endloop
        endmethod

        private static method newForPlayer takes player p returns nothing
            local thistype this = GetPlayerId(p)
            local integer forceCount = GetMapTeams()
            local integer countP = 0
            local integer row = 1
            local thistype h = 0
            //Creating the multiboard for current player.
            set .heroIcon           = DEFAULT_ICON //Default icon.
            set mb.multiboard[this] = CreateMultiboard()
            call MultiboardClear           (mb.multiboard[this])
            call MultiboardSetTitleText    (mb.multiboard[this],KILL_DEATH_COLOR+"0"+"/"+"0"+"|r - "+GradientText(mbTitle))
            call MultiboardSetColumnCount  (mb.multiboard[this],COLUMN_COUNT)
            call MultiboardSetRowCount     (mb.multiboard[this],1+forceCount+GetCountPlayers())
            //Resizing the multiboard.
            call MbSetItemStyle(mb.multiboard[this],0,0,true,false)
            call MbSetItemWidth(mb.multiboard[this],0,0,12.20) //Player name.
            call MbSetItemWidth(mb.multiboard[this],0,1,1.80)  //Cooldown.
            call MbSetItemWidth(mb.multiboard[this],0,2,1.80)  //Player hero level.
            call MbSetItemWidth(mb.multiboard[this],0,3,1.30)  //Player hero kills.
            call MbSetItemWidth(mb.multiboard[this],0,4,1.30)  //Player hero deaths.
            call MbSetItemWidth(mb.multiboard[this],0,5,3.40)  //Player gold.
            call MbSetItemWidth(mb.multiboard[this],0,6,3.40)  //Player lumber.
            call MbSetItemWidth(mb.multiboard[this],0,7,1.20)  //Items slots start.
            call MbSetItemWidth(mb.multiboard[this],0,8,1.20)
            call MbSetItemWidth(mb.multiboard[this],0,9,1.20)
            call MbSetItemWidth(mb.multiboard[this],0,10,1.20)
            call MbSetItemWidth(mb.multiboard[this],0,11,1.20)
            call MbSetItemWidth(mb.multiboard[this],0,12,1.20)
            call MbSetItemWidth(mb.multiboard[this],0,13,1.20)  //Items slots end.
            //Set the team/players data.
            call MbSetItemValue(mb.multiboard[this],0,1,CD_COLOR+COOLDOWN_NAME+"|r")
            call MbSetItemValue(mb.multiboard[this],0,2,LVL_COLOR+LEVEL_NAME+"|r")
            call MbSetItemValue(mb.multiboard[this],0,3,KILL_COLOR+KILL_NAME+"|r")
            call MbSetItemValue(mb.multiboard[this],0,4,DEATH_COLOR+DEATH_NAME+"|r")
            call MbSetItemIcon (mb.multiboard[this],0,5,GOLD_ICON)
            call MbSetItemIcon (mb.multiboard[this],0,6,LUMBER_ICON)
            call MbSetItemValue(mb.multiboard[this],0,7,ITEM_COLOR+"   i"+"|r")
            call MbSetItemValue(mb.multiboard[this],0,8,ITEM_COLOR+"  t"+"|r")
            call MbSetItemValue(mb.multiboard[this],0,9,ITEM_COLOR+" e"+"|r")
            call MbSetItemValue(mb.multiboard[this],0,10,ITEM_COLOR+"m"+"|r")
            call MbSetItemValue(mb.multiboard[this],0,11,ITEM_COLOR+" s"+"|r")
            //Adding Teams.
            loop
                exitwhen h == forceCount
                if h != 0 then
                    set countP = countP+CountPlayersInForce(h-1)
                    set row = 1+countP+h
                endif
                set h.teamIndex = row
                call MbSetItemValue(mb.multiboard[this],row,0,GradientText(TEAM_COLOR_1+DEFAULT_TEAM_NAME+" "+I2S(h+1)+TEAM_COLOR_2))
                call MbSetItemValue(mb.multiboard[this],row,3,KILL_COLOR+"0|r")
                call MbSetItemValue(mb.multiboard[this],row,4,DEATH_COLOR+"0|r")
                set h = h+1
            endloop
            //Adding players to current multiboard.
            call .addPlayers()
            //Hide multiboard for player.
            if GetLocalPlayer() == p then
                call MultiboardDisplay(mb.multiboard[this],false)
            endif
        endmethod 
        
        //Textmacro #3, used to update gold and lumber.
        //! textmacro Update takes WHICH_UPDATE,WHICH_RESOURCE,VAR_NAME,INT_COLUMN
        private static method update$WHICH_UPDATE$ takes nothing returns boolean
            local player p1     = GetTriggerPlayer()
            local thistype i    = GetPlayerId(p1)
            local thistype this = 0
            local integer row   = 2+GetPlayerForceIndex(i)+GetPlayerIdInForce(i)
            local player p
            set i.$VAR_NAME$ = GetPlayerState(p1,PLAYER_STATE_RESOURCE_$WHICH_RESOURCE$)
            loop
                exitwhen this == bj_MAX_PLAYERS
                set p = Player(this)
                if GetPlayerSlotState(p) == PLAYER_SLOT_STATE_PLAYING then
                    if IsPlayerAlly(p,p1) then
                        call MbSetItemValue(mb.multiboard[this],row,$INT_COLUMN$,$WHICH_RESOURCE$_COLOR+I2S(i.$VAR_NAME$)+"|r")
                    endif
                endif
                set this = this+1
            endloop
            return false
        endmethod
        //! endtextmacro
        
        //! runtextmacro Update("Gold","GOLD","gold","5")
        //! runtextmacro Update("Lumber","LUMBER","lumber","6")
        
        //Updapting kills/deaths method.
        private static method updateKillsDeaths takes nothing returns boolean
            local unit deathUnit   = GetDyingUnit()
            local unit killingUnit = GetKillingUnit()
            local thistype p1      = GetPlayerId(GetOwningPlayer(deathUnit))
            local thistype p2      = GetPlayerId(GetOwningPlayer(killingUnit))
            local thistype t1      = GetPlayerForceIndex(p1)
            local thistype t2      = GetPlayerForceIndex(p2)
            local thistype this    = 0
            local integer row1     = 2+GetPlayerForceIndex(p1)+GetPlayerIdInForce(p1)
            local integer row2     = 2+GetPlayerForceIndex(p2)+GetPlayerIdInForce(p2)
            if deathUnit == p1.boardHero and killingUnit == p2.boardHero then
                set p2.kill       = p2.kill+1
                set t2.teamKills  = t2.teamKills+1
                set p1.death      = p1.death+1
                set t1.teamDeaths = t1.teamDeaths+1
                loop
                    exitwhen this == bj_MAX_PLAYERS
                    if GetPlayerSlotState(Player(this)) == PLAYER_SLOT_STATE_PLAYING then
                        call MbSetItemValue(mb.multiboard[this],row2,3,KILL_COLOR+I2S(p2.kill)+"|r")
                        call MbSetItemValue(mb.multiboard[this],row1,4,DEATH_COLOR+I2S(p1.death)+"|r")
                    endif
                    call MbSetItemValue(mb.multiboard[this],t2.teamIndex,3,KILL_COLOR+I2S(t2.teamKills)+"|r")
                    call MbSetItemValue(mb.multiboard[this],t1.teamIndex,4,DEATH_COLOR+I2S(t1.teamDeaths)+"|r")
                    set this = this+1
                endloop
                call MultiboardSetTitleText(mb.multiboard[p2],KILL_DEATH_COLOR+I2S(p2.kill)+"/"+I2S(p2.death)+"|r - "+GradientText(mbTitle))
                call MultiboardSetTitleText(mb.multiboard[p1],KILL_DEATH_COLOR+I2S(p1.kill)+"/"+I2S(p1.death)+"|r - "+GradientText(mbTitle))
            endif
            set deathUnit   = null
            set killingUnit = null
            return false
        endmethod
        
        //Updapting levels.
        private static method updateLevel takes nothing returns boolean
            local unit u        = GetTriggerUnit()
            local thistype i    = GetPlayerId(GetOwningPlayer(u))
            local thistype this = 0
            local integer row   = 2+GetPlayerForceIndex(i)+GetPlayerIdInForce(i)
            if u == i.boardHero and IsUnitType(u,UNIT_TYPE_HERO) then
                set i.level = GetUnitLevel(u)
                //! runtextmacro UpdateMultiboard("//","//","//","row","2","LVL_COLOR+I2S(i.level)+CLOSE")
            endif
            set u = null
            return false
        endmethod
        
        //Init items icons: I used this method detached from .initMultiboard because 
        //for some reason the multiboard is not complety created for all players when 
        //used many loops at same time.
        private static method initItemsIcons takes nothing returns boolean
            local integer i = 0
            local integer h = 0
            local integer n = 7
            local integer row
            loop
                exitwhen i == bj_MAX_PLAYERS
                if GetPlayerSlotState(Player(i)) == PLAYER_SLOT_STATE_PLAYING then
                    loop
                        exitwhen h == bj_MAX_PLAYERS
                        set row = 2+GetPlayerForceIndex(h)+GetPlayerIdInForce(h)
                        loop
                            exitwhen n == 13
                            call MbSetItemIcon (mb.multiboard[i],row,n,DEFAULT_ICON)
                            call MbSetItemStyle(mb.multiboard[i],row,n,true,true)
                            set n = n+1
                        endloop
                        set n = 7
                        set h = h+1
                    endloop
                    set h = 0
                endif
                set i = i+1
            endloop
            return false
        endmethod
        
        //Init the multiboard for the 12 players.
        private static method initMultiboard takes nothing returns boolean
            local integer i = 0
            local integer n = 7
            local integer row
            local player p
            set mbTitle = TITLE_COLOR_1+BOARD_TITLE+TITLE_COLOR_2
            loop
                exitwhen i == bj_MAX_PLAYERS
                set p = Player(i)
                if GetPlayerSlotState(p) == PLAYER_SLOT_STATE_PLAYING then
                    call .newForPlayer(p)
                endif
                set i = i+1
            endloop
            return false
        endmethod
        
        private static method onInit takes nothing returns nothing
            local integer i = 0
            local trigger t
            local player p
            local integer r
            set mb = Table.create()
            call ConfigPlayersColors()
            //When, here is the init with more textmacros....
            //! textmacro TriggerEvent takes IS_TIMER_EVENT,TIME_OUT,IS_ANY_EVENT,EVENT_NAME,METHOD_NAME
            set t = CreateTrigger()
            $IS_TIMER_EVENT$call TriggerRegisterTimerEvent(t,$TIME_OUT$,false)
            $IS_ANY_EVENT$call TriggerRegisterAnyUnitEventBJ(t,EVENT_PLAYER_$EVENT_NAME$)
            call TriggerAddCondition(t,function thistype.$METHOD_NAME$)
            //! endtextmacro
            //! runtextmacro TriggerEvent("","MULTIBOARD_INIT","//","","initMultiboard")
            //! textmacro StaticIf takes WHICH_STATIC,INT_COLUMN,CODE_NAME
            static if not USE_$WHICH_STATIC$ then
                set COLUMN_COUNT = COLUMN_COUNT-$INT_COLUMN$
            else
                set t = CreateTrigger()
                loop
                    exitwhen i == bj_MAX_PLAYERS
                    set p = Player(i)
                    set r = GetPlayerState(p,PLAYER_STATE_RESOURCE_$WHICH_STATIC$)
                    call TriggerRegisterPlayerStateEvent(t,p,PLAYER_STATE_RESOURCE_$WHICH_STATIC$,GREATER_THAN,r)
                    call TriggerRegisterPlayerStateEvent(t,p,PLAYER_STATE_RESOURCE_$WHICH_STATIC$,LESS_THAN,r)
                    set i = i+1
                endloop
                call TriggerAddCondition(t,function thistype.update$CODE_NAME$)
                set i = 0
            endif
            //! endtextmacro
            //! runtextmacro StaticIf("GOLD","1","Gold")
            //! runtextmacro StaticIf("LUMBER","1","Lumber")
            static if not USE_ITEMS then
                set COLUMN_COUNT = COLUMN_COUNT-6
            else
                //! runtextmacro TriggerEvent("","MULTIBOARD_INIT+0.01","//","","initItemsIcons")
            endif
            //! runtextmacro TriggerEvent("//","","","UNIT_DEATH","updateKillsDeaths")
            //! runtextmacro TriggerEvent("//","","","HERO_LEVEL","updateLevel")
        endmethod
    endstruct
endlibrary
