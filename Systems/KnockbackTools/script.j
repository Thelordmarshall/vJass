library KnockbackTools uses Optimizer32, DestructableLibII, Event, AutoFly, GetUnitCollision
/*****************************************************************************
*
*   KnockbackTools
*   _______________
*   v1.1.1.2
*   by Thelordmarshall
*   
*   Well another fucking Knockback system...
*
*   Pros:
*   _____
*   You can:
*       - Use slide speed or not.
*       - Use fly on launch targets.
*       - Create functions for loop/stop events.
*       - And more....
*
*   API:
*   ____
*   struct Knockback extends array:
*       - method launch takes real angle, real distance returns nothing
*           - Launch the target.
*   method operator:
*       - useSlideSpeed (boolean)
*       - speed (real)
*       - timerSpeed (real)
*       - arc (real)
*       - fx (string)
*       - pathing (boolean)
*       - pause (boolean)
*       - fly (boolean)
*       - hitTrees (boolean)
*   
*   Functions:
*   __________
*       - function Parabola takes real arc, real d, real x returns real
*       - function ParabolicMovement takes real h, real d, real x returns real
*
*   Credits:
*   ________
*       - Nestharus: Event.
*       - PitzerMike: DestructableLib.
*       - moyackx: Parabolic formulas.
*
*   Copyright © 2015.
*****************************************************************************/

    //CONFIGURATION
    //=======================================================
    globals
        private constant real ARC_LIMIT = 1.
        //private constant real RATIO     = 200.
    endglobals
    //=======================================================
    //ENDCONFIGURATION
    
    function Parabola takes real arc, real d, real x returns real
        return (4*arc)*(d-x)*(x/d)
    endfunction

    function ParabolicMovement takes real h, real d, real x returns real
        local real a=-4*h/(d*d)
        local real b=4*h/d
        return a*x*x+b*x
    endfunction
    
    //Core
    struct Knockback extends array
        readonly static Event EVENT_LOOP
        readonly static Event EVENT_STOP
        private static integer more=0
        private static integer array list
        static integer instanceData=0
        static unit lastStopedUnit=null
        static unit loopUnit=null
        private unit u
        private real d1
        private real d2
        private real sin
        private real cos
        private real x
        private real y
        private unit kb_targetUnit
        private real kb_distance
        private real kb_speed
        private real kb_timerSpeed
        private real kb_arc
        private integer kb_data
        private string kb_fx
        private boolean kb_collision
        private boolean kb_pause
        private boolean kb_slideSpeed
        private boolean kb_hitTrees
        private Timer32 t32
        
        private static method destroyDelay takes nothing returns nothing
            local thistype this=Timer32.getData()
            set list[this]=list[0]
            set list[0]=this
            if(.u!=null)then
                set lastStopedUnit=.u
                set instanceData=.kb_data
                call FireEvent(Knockback.EVENT_STOP)
                set lastStopedUnit=null
                if(.kb_pause)then
                    call PauseUnit(.u,false)
                endif
                if(not .kb_collision)then
                    call SetUnitPathing(.u,true)
                endif
                if(.kb_arc>0.)then
                    call SetUnitFlyHeight(.u,GetUnitDefaultFlyHeight(.u),0.)
                endif
                set .u=null
            endif
            set .kb_targetUnit=null
        endmethod
        
        method manualDestroy takes nothing returns nothing
            call .t32.stop()
            call Timer32.start(this,.02,function thistype.destroyDelay)
        endmethod
        
        private static method onLoop takes nothing returns nothing
            local thistype this=Timer32.getData()
            local real x=GetUnitX(.u)
            local real y=GetUnitY(.u)
            local real x2
            local real y2
            local real a
            local real d
            if(GetUnitTypeId(.u)!=0)then
                set loopUnit=.u
                call FireEvent(Knockback.EVENT_LOOP)
                set loopUnit=null
                if(.kb_pause and not IsUnitPaused(.u))then
                    call PauseUnit(.u,true)
                endif
                if(.kb_targetUnit!=null)then
                    set x2=GetUnitX(.kb_targetUnit)
                    set y2=GetUnitY(.kb_targetUnit)
                    set a=Atan2(y2-y,x2-x)
                    set .cos=Cos(a)
                    set .sin=Sin(a)
                    set .kb_distance=SquareRoot(Pow(x2-.x,2)+Pow(y2-.y,2))
                endif
                if(.kb_slideSpeed)then
                    set x=x+.d1*.cos
                    set y=y+.d1*.sin
                    set .d1=.d1-.d2
                else
                    set x=x+.kb_speed*.cos
                    set y=y+.kb_speed*.sin
                endif
                set d=SquareRoot(Pow(x-.x,2)+Pow(y-.y,2))
                if d<=.kb_distance then
                    call SetUnitPosition(.u,x,y)
                    if (.kb_fx!=null or .kb_fx!="") then
                        call DestroyEffect(AddSpecialEffect(.kb_fx,x,y))
                    endif
                    if(.kb_arc>0.)then
                        if .kb_arc>-ARC_LIMIT and .kb_arc<ARC_LIMIT then
                            call SetUnitFlyHeight(.u,Parabola(.kb_arc,.kb_distance,d),0.)
                        else
                            call SetUnitFlyHeight(.u,ParabolicMovement(.kb_arc,.kb_distance,d),0.)
                        endif
                    endif
                    if(.kb_hitTrees)then
                        call KillDestructablesInRange(x,y,GetUnitCollision(.u))
                    endif
                endif
                if(.kb_slideSpeed and .d1<=0.)then
                    call .manualDestroy()
                elseif(not .kb_slideSpeed and d>=.kb_distance)then
                    call .manualDestroy()
                endif
            else
                call .manualDestroy()
            endif
        endmethod

        method launch takes real a, real d, real speed returns nothing
            local integer q=R2I(.kb_timerSpeed/Timer32.PERIOD)
            set .kb_distance=d
            set .kb_speed=speed
            set .x=GetUnitX(.u)
            set .y=GetUnitY(.u)
            set .cos=Cos(a)
            set .sin=Sin(a)
            if(.kb_slideSpeed)then
                set .d1=2*d/(q+1)
                set .d2=.d1/q
            endif
            call SetUnitPathing(.u,.kb_collision)
            set .t32=Timer32.start(this,0,function thistype.onLoop)
        endmethod
        
        static method create takes unit forWhichUnit returns Knockback
            local thistype this=list[0]
            if this==0 then
                set this=more+1
                set more=this
            else
                set list[0]=list[this]
            endif
            set .u=forWhichUnit
            return this
        endmethod
        
        //! textmacro kb_operator takes OPERATOR_NAME,VAR_TYPE,VAR_NAME
        method operator $OPERATOR_NAME$= takes $VAR_TYPE$ $VAR_NAME$ returns nothing
            set .kb_$OPERATOR_NAME$=$VAR_NAME$
        endmethod
        //! endtextmacro
        
        //! runtextmacro kb_operator("targetUnit","unit","u")
        //! runtextmacro kb_operator("data","integer","d")
        //! runtextmacro kb_operator("slideSpeed","boolean","b")
        ////! runtextmacro kb_operator("speed","real","s")
        //! runtextmacro kb_operator("timerSpeed","real","s")
        //! runtextmacro kb_operator("arc","real","a")
        //! runtextmacro kb_operator("fx","string","f")
        ///! runtextmacro kb_operator("stop","boolean","b")
        //! runtextmacro kb_operator("collision","boolean","b")
        //! runtextmacro kb_operator("pause","boolean","b")
        //! runtextmacro kb_operator("hitTrees","boolean","b")

        static method registerEvent takes boolexpr c, Event ev returns nothing
            call ev.register(c)
        endmethod
        
        private static method onInit takes nothing returns nothing
            set EVENT_LOOP=CreateEvent()
            set EVENT_STOP=CreateEvent()
        endmethod
    endstruct
endlibrary
