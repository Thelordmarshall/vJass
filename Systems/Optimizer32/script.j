library Optimizer32/*
**************************************************************************************
*
*   **********************************************************************************
*
*   */ uses /*
*       */ Table /* hiveworkshop.com/forums/jass-functions-413/snippet-new-table-188084/
*
*   **********************************************************************************
*
*   Optimizer32
*   ___________
*   v1.0.1.2
*   by Thelordmarshall
*   
*   One map, one timer (well less timers)... Created from TimerUtils, T32 and CTL.   
*   Optimizer32 is designed to reduce lag caused by start timers a lot of times...
*
*   Periodic time: .031250000 (period used for most spells and systems).
*
*   Pros:
*   _____
*       - Easy way to use.
*       - You can attach integers for each timer "started", similar to TimerUtils.
*       - Use periodic time or not.
*
*   Cons:
*   _____
*       - I haven't found anything bad so far.
*
*   API:
*   ____
*   struct Timer32:
*       - static constant real PERIOD
*           - Public t32 constant period var (Timer32.PERIOD).
*       - static integer data
*           - Public t32 user data (Timer32.data).
*       - static Timer32 expired
*           - Public t32 expired timer (Timer32.expired).
*       - static method start takes integer data, real duration, code c returns Timer32
*           - Start timer: takes integer data, real duration and code c; if duration 
*             is>0 then the timer will be a non periodic time.
*       - static method getExpired takes nothing returns Timer32
*           - Return expired timer.
*       - static method getData takes nothing returns integer
*           - Get the data for your loop function.
*       - method isRunning takes nothing returns boolean
*           - Check if timer instance is running.
*       - method stop takes nothing returns nothing
*           - Stop timer (manually).
*   
*   Credits:
*   ________
*       - Vexorian: TimerUtils.
*       - Jesus4Lyf: T32.
*       - Nestharus: CTL and help me with some tips ^_^.
*
*   Notes:
*   ______
*       - All suggestions are welcome.
*   
*   Copyright © 2015.
************************************************************************************/
    struct Timer32
        static integer data=0
        static Timer32 expired=0
        static constant real PERIOD=.03125
        private static timer t32=CreateTimer()
        private static boolean active=false
        private static Table timerList=0
        private static integer next=0
        private static integer prev=0
        private static integer triggerList=0
        private static trigger array t
        private real d
        private integer q
        private integer n
        private integer c
        private boolean a
        private boolean p
        
        private static method getCondition takes boolexpr c returns integer
            local integer i=0
            loop
                exitwhen(i==triggerList)
                if(c==timerList.boolexpr[i])then
                    return i
                endif
                set i=i+1
            endloop
            set i=triggerList
            set t[triggerList]=CreateTrigger()
            call TriggerAddCondition(t[triggerList],c)
            set timerList.boolexpr[triggerList]=c
            set triggerList=triggerList+1
            return i
        endmethod

        private static method loop32 takes nothing returns nothing
            local integer i=0
            local thistype this
            loop
                exitwhen(i>next)
                if(timerList.integer.has(i))then
                    set this=timerList.integer[i]
                    set data=.q
                    set expired=this
                    if(not.p)then
                        set .d=.d-PERIOD
                        if(.d<=0.)then
                            call TriggerEvaluate(t[.c])
                            call .stop()
                        endif
                    else
                        call TriggerEvaluate(t[.c])
                    endif
                endif
                set i=i+1
            endloop
        endmethod
        
        static method getExpired takes nothing returns Timer32
            return expired
        endmethod
        static method getData takes nothing returns integer
            return data
        endmethod
        method isRunning takes nothing returns boolean
            return .a
        endmethod
        
        static method start takes integer data, real duration, code c returns Timer32
            local thistype this
            set next=next+1
            set prev=prev+1
            set this=next
            if(not.a)then
                set .q=data
                set .a=true
                set .d=duration
                set .p=(.d==0)
                set .n=next
                set .c=getCondition(Condition(c))
                set timerList.integer[next]=this
                if(not active)then
                    set active=true
                    call TimerStart(t32,PERIOD,true,function thistype.loop32)
                endif
                return this
            else
                call .stop()
                debug call DisplayTimedTextToPlayer(GetLocalPlayer(),0.,0.,60.,"[Optimizer32] error: timer32 instance ["+I2S(this)+"] is already started.")
            endif
            return-1
        endmethod
        
        method stop takes nothing returns nothing
            set .a=false
            set .p=false
            set prev=prev-1
            call timerList.remove(.n)
            if(prev==0)then
                set next=0
                if(active)then
                    set active=false
                    call PauseTimer(t32)
                endif
            endif
        endmethod
        
        private static method onInit takes nothing returns nothing
            set timerList=Table.create()
        endmethod
    endstruct
endlibrary
