library DestructableLibII initializer Init
/*********************************************************************************
*
*   DestructableLibII
*   _________________
*   v1.0.1.1
*   Originally made by PitzerMike, update by Thelordmarshall.
*   
*   This is a useful compilation of all custom destructable functions in one 
*   library.
*   
*   API:
*   ____
*       - function IsDestructableDead takes destructable d returns boolean
*       - function IsDestructableTree takes destructable d returns boolean
*       - function KillDestructablesInRange takes real x, real y, real range returns boolean
*       - function ReviveDestructable takes destructable d, boolean birth returns boolean
*
*   Credits: PitzerMike.
**********************************************************************************/

    globals
        private constant integer DUMMY_ID         = 'uloc'  // locust
        private constant integer HARVEST_ID       = 'Ahrl'  // ghouls harvest
        private constant integer HARVEST_ORDER_ID = 0xD0032 // harvest order ID
        private integer i=0
        private unit u=null
    endglobals
    
    function IsDestructableDead takes destructable d returns boolean
        return GetDestructableLife(d)<=.405
    endfunction
    
    function IsDestructableTree takes destructable d returns boolean
        return IssueTargetOrderById(u,HARVEST_ORDER_ID,d)
    endfunction
    
    private function KillTrees takes nothing returns nothing
        local destructable d=GetEnumDestructable()
        if(d!=null and not IsDestructableDead(d) and IsDestructableTree(d))then
            call KillDestructable(d)
            set i=i+1
        endif
        set d=null
    endfunction
    
    function KillDestructablesInRange takes real x, real y, real range returns boolean
        local rect r=Rect(x-range,y-range,x+range,y+range)
        set i=0
        call EnumDestructablesInRect(r,null,function KillTrees)
        call RemoveRect(r)
        set r=null
        return i>0
    endfunction
    
    function ReviveDestructable takes destructable d, boolean birth returns boolean
        if(IsDestructableDead(d))then
            call DestructableRestoreLife(d,GetDestructableMaxLife(d),birth)
            return true
        endif
        return false
    endfunction
    
    private function Init takes nothing returns nothing
        set u=CreateUnit(Player(15),DUMMY_ID,0.,0.,0.)
        call ShowUnit(u,false)
        call UnitAddAbility(u,HARVEST_ID)
        call UnitRemoveAbility(u,'Amov')
    endfunction
endlibrary
