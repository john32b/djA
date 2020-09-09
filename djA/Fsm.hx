package djA;


/**
 * Simple Finite Machine State
 */
@:publicFields
class FsmState {
	var name:EnumValue;
	var onEnter:Void->Void;
	var onUpdate:Void->Void;
	var onExit:Void->Void;
	public function new(Name:EnumValue, ?Enter:Void->Void, ?Update:Void->Void, ?Exit:Void->Void) {
		name = Name;
		onEnter = Enter;
		onUpdate = Update;
		onExit = Exit;
	}//---------------------------------------------------;
}// --


/**
 * Simple Finite State Machine
 */
class Fsm
{
	// Optionally pre-save the states
	var states:Map<EnumValue,FsmState>;
	
	var currentState:FsmState;
	
	public var lastStateName(default, null):EnumValue;
	public var currentStateName(default, null):EnumValue;
	
	//====================================================;
	
	public function new() 
	{
		states = new Map();
		lastStateName = null;
		currentStateName = null;
		currentState = null;
	}//---------------------------------------------------;
	
	/**
	 * Add a new state to the pool
	 */
	public function addState(Name:EnumValue, ?Enter:Void->Void, ?Update:Void->Void, ?Exit:Void->Void) 
	{
		states.set(Name, new FsmState(Name, Enter, Update, Exit));
	}//---------------------------------------------------;
	
	/**
	   Switch to a state immediately.
	**/
	public function switchTo(st:FsmState)
	{
		if (currentState != null) {
			if (currentState.onExit != null) currentState.onExit();
			lastStateName = currentState.name;
		}
		
		currentState = st;
		if (currentState != null)  {
			currentStateName = currentState.name;
			if (currentState.onEnter != null) currentState.onEnter();
		}else{
			currentStateName = null;
		}
	}//---------------------------------------------------;
	
	/**
	 * Switch to a state you have already added
	 */
	public function goto(Name:EnumValue) 
	{
		switchTo(states.get(Name));
	}//---------------------------------------------------;
	
	/**
	 * Call this on every update()
	 */
	public function update() 
	{
		if (currentState != null && currentState.onUpdate != null) {
			currentState.onUpdate();
		}
	}//---------------------------------------------------;
	
} // --