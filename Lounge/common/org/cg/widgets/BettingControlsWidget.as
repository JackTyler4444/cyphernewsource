/**
* Implements poker betting controls via integration with the currently active PokerBettingModule instance.
* 
* (C)opyright 2014 to 2017
*
* This source code is protected by copyright and distributed under license.
* Please see the root LICENSE file for terms and conditions.
*
*/ 

package org.cg.widgets {
	
	import feathers.controls.Check;
	import org.cg.SlidingPanel;
	import org.cg.interfaces.ILounge;
	import org.cg.interfaces.IPanelWidget;
	import PokerCardGame;
	import PokerBettingModule;
	import events.PokerBettingEvent;
	import events.PokerGameStatusEvent;
	import org.cg.DebugView;
	import feathers.controls.Button;
	import feathers.controls.NumericStepper;
	//import feathers.controls.Slider;
	import org.cg.CurrencyFormat;
	import org.cg.interfaces.IWidget;
	import starling.events.Event;

	public class BettingControlsWidget extends Widget implements IWidget {
		
		//UI components rendered by StarlingViewManager:
		public var betButton:Button;
		public var checkCallButton:Button;
		public var foldButton:Button;
		public var increaseBetButton:Button;
		public var decreaseBetButton:Button;
		public var betIncreaseStepper:NumericStepper;
		//public var betSlider:Slider;
		public var hotBetOneButton:Button;
		public var hotBetTwoButton:Button;
		public var hotBetThreeButton:Button;
		public var allInButton:Button;
		public var foldToAnyBetCheck:Check;
		protected var _game:PokerCardGame = null; //reference to associated PokerCardGame instance
		protected var _bettingModule:PokerBettingModule = null; //reference to associated PokerBettingModule instance
		private var _currentMinimumAmount:Number = Number.NEGATIVE_INFINITY; //minimum bet amount set at last enable event
		private var _currentMaximumAmount:Number = Number.NEGATIVE_INFINITY; //minimum bet amount set at last enable event
		private var _currentAmount:Number = Number.NEGATIVE_INFINITY; //current bet amount
		private var _currencyFormatter:CurrencyFormat; //used to format betting values for display
		private var _counter:Number = 1;
		
		/**
		 * Creates a new instance.
		 * 
		 * @param	loungeRef A reference to the main ILounge implementation instance.
		 * @param	containerRef The widget's parent panel or display object container.
		 * @param	widgetData The widget's configuration XML data, usually from the global settings data.
		 */
		public function BettingControlsWidget(loungeRef:ILounge, containerRef:*, widgetData:XML) {
			DebugView.addText ("BettingControlsWidget created");
			this._game = loungeRef.games[0] as PokerCardGame;
			this._bettingModule = this._game.bettingModule;	
			this._currencyFormatter = new CurrencyFormat();
			super(loungeRef, containerRef, widgetData);
		}
		
		/**
		 * Initalizes the instance after it's been added to the display list and all pre-defined child components have been rendered.
		 */
		override public function initialize():void {
			DebugView.addText ("BettingControlsWidget.initialize");
			this._bettingModule.addEventListener(PokerBettingEvent.BETTING_DISABLE, this.disableControls);
			this._bettingModule.addEventListener(PokerBettingEvent.BETTING_ENABLE, this.enableControls);
			this._bettingModule.addEventListener(PokerBettingEvent.BET_UPDATE, this.onBetUpdate);
			this._bettingModule.addEventListener(PokerBettingEvent.BETTING_PLAYER, this.onBettingPlayerUpdate);
			this._game.addEventListener(PokerGameStatusEvent.DESTROY, this.onGameDestroy);
			this.betIncreaseStepper.addEventListener(Event.CHANGE, this.onIncreaseStepperChange);
			//this.betIncreaseStepper.isEnabled = true;
		}
		
		/**
		 * Prepares the widget for removal from memory by removing event listeners and clearing references.
		 */
		override public function destroy():void {
			this._game.removeEventListener(PokerGameStatusEvent.DESTROY, this.onGameDestroy);
			this._bettingModule.removeEventListener(PokerBettingEvent.BETTING_DISABLE, this.disableControls);
			this._bettingModule.removeEventListener(PokerBettingEvent.BETTING_ENABLE, this.enableControls);
			this._bettingModule.removeEventListener(PokerBettingEvent.BET_UPDATE, this.onBetUpdate);
			this._bettingModule.removeEventListener(PokerBettingEvent.BETTING_PLAYER, this.onBettingPlayerUpdate);
			this.betIncreaseStepper.removeEventListener(Event.CHANGE, this.onIncreaseStepperChange);
			this.disableControls(null);
			this._game = null;
			this._bettingModule = null;			
			this._currencyFormatter = null;
			super.destroy();
		}
		
		/**
		 * Disables all interactive user interface elements in the widget and removes their event listeners. May be invoked
		 * via an event dispatch or internally from another function.
		 * 
		 * @param	eventObj A PokerBettingEvent object.
		 */
		private function disableControls(eventObj:PokerBettingEvent):void {
			this.betButton.removeEventListener(Event.TRIGGERED, this.onBetButtonClick);
			this.foldButton.removeEventListener(Event.TRIGGERED, this.onFoldButtonClick);
			this.increaseBetButton.removeEventListener(Event.TRIGGERED, this.onIncreaseBetClick);
			this.decreaseBetButton.removeEventListener(Event.TRIGGERED, this.onDecreaseBetClick);
			this.betIncreaseStepper.removeEventListener(Event.CHANGE, this.onIncreaseStepperChange);
			this.hotBetOneButton.removeEventListener(Event.TRIGGERED, this.onHotBetOneButtonClick);
			this.hotBetTwoButton.removeEventListener(Event.TRIGGERED, this.onHotBetTwoButtonClick);
			this.hotBetThreeButton.removeEventListener(Event.TRIGGERED, this.onHotBetThreeButtonClick);
			this.allInButton.removeEventListener(Event.TRIGGERED, this.onAllInButtonClick);
			this.checkCallButton.removeEventListener(Event.TRIGGERED, this.onCheckCallButtonClick);
			this.foldToAnyBetCheck.removeEventListener(Event.TRIGGERED, this.onFoldToAnyBetClick);
			this.betIncreaseStepper.removeEventListener(Event.CHANGE, this.onIncreaseStepperChange);
			
			this.betButton.isEnabled = false;
			this.checkCallButton.isEnabled = false;
			this.foldButton.isEnabled = false;
			this.increaseBetButton.isEnabled = false;
			this.decreaseBetButton.isEnabled = false;
			this.betIncreaseStepper.isEnabled = false;
			this.hotBetOneButton.isEnabled = false;
			this.hotBetTwoButton.isEnabled = false;
			this.hotBetThreeButton.isEnabled = false;
			this.allInButton.isEnabled = false;
			this.hotBetOneButton.isEnabled = false;
			this.foldToAnyBetCheck.isEnabled = false;
			this.betIncreaseStepper.isEnabled = false;
			
		}
		
		/**
		 * Event listener invoked when the 'increase bet' button is clicked. The user interface is updated with the new bet amount.
		 * 
		 * @param	eventObj An Event object.
		 */
		private function onIncreaseBetClick(eventObj:Event):void {
			//var updateAmount:Number = Number(this.betIncreaseStepper.value);
			//this._bettingModule.incrementBet(updateAmount);
		}
		
		/**
		 * Event listener invoked when the 'decrease bet' button is clicked. The user interface is updated with the new bet amount.
		 * 
		 * @param	eventObj An Event object.
		 */
		private function onDecreaseBetClick(eventObj:Event):void {
			//var updateAmount:Number = Number(this.betIncreaseStepper.value);
			//this._bettingModule.decrementBet(updateAmount);
		}
		
		public function betIncreaseStepperAdd():void {
			this.betIncreaseStepper.addEventListener(Event.CHANGE, this.onIncreaseStepperChange);	
		}
		
		public function betIncreaseStepperRemove():void {
			this.betIncreaseStepper.removeEventListener(Event.CHANGE, this.onIncreaseStepperChange);
		}
		
		private function onHotBetOneButtonClick(eventObj:Event):void {
			// sets slider/bet to min
			//set "Bet:" to 0bb
			var betUpdateAmount:Number = 1;
			this._bettingModule.hotBetUpdate(betUpdateAmount);
			//var tempValueOne:Number = this._bettingModule.getBigBlind();
			//var tempValueTwo:Number = (2 * tempValueOne);
			//this.betIncreaseStepper.value = tempValueOne;
			this.betIncreaseStepper.value = (1 * this._bettingModule.bigBlind);
		}
		
		private function onHotBetTwoButtonClick(eventObj:Event):void {
			// sets slider/bet to 3BB
			//betIncreaseStepper
			var betUpdateAmount:Number = 2;
			this._bettingModule.hotBetUpdate(betUpdateAmount);
			//var tempValue:Number = (3 * this._bettingModule.bigBlind());
			//this.betIncreaseStepper.value = (3 * this._bettingModule.bigBlind());
			this.betIncreaseStepper.value = (3 * this._bettingModule.bigBlind);
		}
		
		private function onHotBetThreeButtonClick(eventObj:Event):void {
			// sets slider/bet to Pot
			//betIncreaseStepper
			var betUpdateAmount:Number = 3;
			this._bettingModule.hotBetUpdate(betUpdateAmount);
			//var tempValue:Number = this._bettingModule.communityPot();
			this.betIncreaseStepper.value = this._bettingModule.communityPot;
		}
		
		private function onAllInButtonClick(eventObj:Event):void {
			//sets slider/bet to max/all-in
			//betIncreaseStepper
			var betUpdateAmount:Number = 4;
			this._bettingModule.hotBetUpdate(betUpdateAmount);
			var tempValue:Number = this._bettingModule.maximumTableBet;
			//this.betIncreaseStepper.value = tempValue;
			this.betIncreaseStepper.value = this._bettingModule.maximumTableBet;
		}
		
		//private function onBetSliderChanged(eventObj:Event):void {
			// the bettingtextinputbox (doesn't exists atm)number.  min is the minbet/call. max is current chipstack
			//(shouldn't include chips in pot already). doesn't show when hero is fold or all-in
			
			// Set alpha value of txtOutput to be 1/100 the value of slAlpha.
			//txtOutput.alpha = slAlpha.value/100;
			// Update txtOutput to show its current alpha value.
			//txtOutput.text = "alpha = " + (slAlpha.value/100).toFixed(2);
			// Update nsAlpha to match the value of slAlpha.
			//nsAlpha.value = slAlpha.value
		//}
		
		/**
		 * Event listener invoked when the 'fold' button is clicked. The action is broadcast to other players via the game's betting module.
		 * 
		 * @param	eventObj An Event object.
		 */
		private function onFoldButtonClick(eventObj:Event):void {
			this._bettingModule.onFold();
		}
		
		private function onCheckCallButtonClick(eventObj:Event):void {  
			this._bettingModule.onBetCommit();
			this.disableControls(null);	
		}	
			/**
		 * Event listener invoked when the "commit bet" button has been clicked. The bet is committed and broadcast to other players while the 
		 * user interface is disabled until re-enabled again by an event from the game's betting module.
		 * 
		 * @param	eventObj An Event object.
		 */
		private function onBetButtonClick(eventObj:Event):void {  
			//should update button label with "Raise to / $.$$"  
			//using slider
			this._bettingModule.onBetCommit();
			this.disableControls(null);
		}		
		
		private function onFoldToAnyBetClick(eventObj:Event):void {
			//this._bettingModule.onFold();
			// hero's action is "check" when checkbox is checked and here auto-checks subsequent rounds
			// and folds to any bets.  All betting buttons disappear when check and re-apear 
			//(if visiable otherwise) when uncheked
			
			if (_counter == 1){
			this.disableControls(null);
			this.foldToAnyBetCheck.isEnabled = true;
			this.foldToAnyBetCheck.addEventListener(Event.TRIGGERED, this.onFoldToAnyBetClick);
			_counter = 2;
			
			} 
			else {
				this.enableControlsUncheck(null);
				_counter = 1;
			}
		}	
		
		//private function onCheckCallAny(eventObj:Event):void {
			// check calls any bets
		//}	
		
		/**
		 * Event listener invoked when the bet amount stepper changes. The amount by which the increase or decrease bet buttons
		 * will increase or decrease a bet is updated in the user interface.
		 * 
		 * @param	eventObj An Event object.
		 */
		private function onIncreaseStepperChange(eventObj:Event):void {
			
			//debugSwitch = false;
			//this._bettingModule.debugSwitch(false);
			this._bettingModule._debugSwitch = false;
			
			var matchingWidgets:Vector.<IWidget> = getInstanceByClass("org.cg.widgets.BettingInfoWidget");
			var bettingInfoWidget:BettingInfoWidget = matchingWidgets[0] as BettingInfoWidget;
			
			bettingInfoWidget.killBetInputBoxListener();
			this._bettingModule.removeEventListener(PokerBettingEvent.BET_UPDATE, this.onBetUpdate);
			
			///this.setMinMax();
			
			var tempInc:Number = this.betIncreaseStepper.value;
			
			this._bettingModule.updateBetBox(tempInc);
			//this.updateInterface(tempInc);
			
			//this.betIncreaseStepper.value = tempInc;
			
			this._bettingModule.addEventListener(PokerBettingEvent.BET_UPDATE, this.onBetUpdate);
			bettingInfoWidget.reviveBetInputBoxListener();
			
			//debugSwitch = true;
		}
		
		public function setMinMax():void {
			
			this.betIncreaseStepper.maximum = this._bettingModule.maximumTableBet;
			this.betIncreaseStepper.minimum = this._bettingModule.bigBlind;
			
		}
		
		/**
		 * Enables the user interface and adds event listeners to all components in the widget. May be triggered via an
		 * external event or from another widget function.
		 * 
		 * @param	eventObj A PokerBettingEvent object.
		 */
		private function enableControls(eventObj:PokerBettingEvent):void {
			this.betButton.addEventListener(Event.TRIGGERED, this.onBetButtonClick);
			this.foldButton.addEventListener(Event.TRIGGERED, this.onFoldButtonClick);
			this.increaseBetButton.addEventListener(Event.TRIGGERED, this.onIncreaseBetClick);
			this.decreaseBetButton.addEventListener(Event.TRIGGERED, this.onDecreaseBetClick);
			this.betIncreaseStepper.addEventListener(Event.CHANGE, this.onIncreaseStepperChange);
			this.hotBetOneButton.addEventListener(Event.TRIGGERED, this.onHotBetOneButtonClick);
			this.hotBetTwoButton.addEventListener(Event.TRIGGERED, this.onHotBetTwoButtonClick);
			this.hotBetThreeButton.addEventListener(Event.TRIGGERED, this.onHotBetThreeButtonClick);
			this.allInButton.addEventListener(Event.TRIGGERED, this.onAllInButtonClick);
			this.checkCallButton.addEventListener(Event.TRIGGERED, this.onCheckCallButtonClick);
			this.foldToAnyBetCheck.addEventListener(Event.TRIGGERED, this.onFoldToAnyBetClick);
			//this.betSlider.isEnabled = true;
			
			this.hotBetOneButton.isEnabled = true;
			this.hotBetTwoButton.isEnabled = true;
			this.hotBetThreeButton.isEnabled = true;
			this.allInButton.isEnabled = true;
			this.betButton.isEnabled = true;
			this.checkCallButton.isEnabled = true;
			this.foldButton.isEnabled = true;
			this.foldToAnyBetCheck.isEnabled = true;
			this.betIncreaseStepper.isEnabled = true;
			//this.betIncreaseStepper.maximum = this._bettingModule.maximumTableBet;
			//this.betIncreaseStepper.minimum = this._bettingModule.bigBlind;
			
			//enable check button if not facing a bet,
			//call button if facing a bet with updated label,
			//enable 4 hot bet buttons all listeners
			//check/call checkbox
			
			//facingBet;
			//must be passed in with the BetCommit function
			//disappear if all-in or fold
			//if (facingBet == 0){
			// CheckCallButton Lablel = "Check";
			//}
			//else {
			//	CheckCallButton Lablel = "Call" + facing bet;
			//}
			//make sure bet is "facingBet" not new hero betting
			//input
			
			this._currentAmount = eventObj.amount;
			this._currentMinimumAmount = eventObj.minimumAmount;
			this._currentMaximumAmount = eventObj.maximumAmount;
			this.updateInterface(eventObj.amount);
		}
		
		private function enableControlsUncheck(eventObj:PokerBettingEvent):void {
			// fold to any bet
			this.betButton.addEventListener(Event.TRIGGERED, this.onBetButtonClick);
			this.foldButton.addEventListener(Event.TRIGGERED, this.onFoldButtonClick);
			this.increaseBetButton.addEventListener(Event.TRIGGERED, this.onIncreaseBetClick);
			this.decreaseBetButton.addEventListener(Event.TRIGGERED, this.onDecreaseBetClick);
			this.betIncreaseStepper.addEventListener(Event.CHANGE, this.onIncreaseStepperChange);
			this.hotBetOneButton.addEventListener(Event.TRIGGERED, this.onHotBetOneButtonClick);
			this.hotBetTwoButton.addEventListener(Event.TRIGGERED, this.onHotBetTwoButtonClick);
			this.hotBetThreeButton.addEventListener(Event.TRIGGERED, this.onHotBetThreeButtonClick);
			this.allInButton.addEventListener(Event.TRIGGERED, this.onAllInButtonClick);
			this.checkCallButton.addEventListener(Event.TRIGGERED, this.onCheckCallButtonClick);
			this.foldToAnyBetCheck.addEventListener(Event.TRIGGERED, this.onFoldToAnyBetClick);
			//this.betSlider.isEnabled = true;
			
			this.hotBetOneButton.isEnabled = true;
			this.hotBetTwoButton.isEnabled = true;
			this.hotBetThreeButton.isEnabled = true;
			this.allInButton.isEnabled = true;
			this.betButton.isEnabled = true;
			this.checkCallButton.isEnabled = true;
			this.foldButton.isEnabled = true;
			this.foldToAnyBetCheck.isEnabled = true;
			this.betIncreaseStepper.isEnabled = true;
			//this.betIncreaseStepper.maximum = this._bettingModule.maximumTableBet;
			//this.betIncreaseStepper.minimum = this._bettingModule.bigBlind;
		}
		/**
		 * Updates the widget's UI with a new bet amount, optionally enabling or disabling buttons depending on the players' available
		 * balances.
		 * 
		 * @param	amount The bet amount to update in the UI. This is an additive value and is formatted using the current currency
		 * settings before being updated in the UI.
		 * @param	updateButtons If true, the increase and decrease bet buttons are enabled or disabled to ensure that the bet amount can't 
		 * exceed any player's maximum available balance.
		 */
		private function updateInterface(amount:Number, updateButtons:Boolean = true):void {
			var totalIncAmount:Number = amount + Number(this.betIncreaseStepper.value);			
			totalIncAmount = this._currencyFormatter.roundToFormat(totalIncAmount, this._bettingModule.currentSettings.currencyFormat);
			var totalDecAmount:Number = amount - Number(this.betIncreaseStepper.value);			
			totalDecAmount = this._currencyFormatter.roundToFormat(totalDecAmount, this._bettingModule.currentSettings.currencyFormat);
			if (updateButtons) {
				//if (totalDecAmount >= this._currentMinimumAmount) {
				//	this.decreaseBetButton.isEnabled = true;
				//} else {
				//	this.decreaseBetButton.isEnabled = false;
				//}
				//if (totalIncAmount <= this._currentMaximumAmount) {
				//	this.increaseBetButton.isEnabled = true;
				//} else {
				//	this.increaseBetButton.isEnabled = false;
				//}
				this.betIncreaseStepper.isEnabled = true;
			}
		}
		
		/**
		 * Event listener invoked whenever a player's bet amount is updated. The 'updateInterface' method is invoked to update
		 * the interface with the new bet value.
		 * 
		 * @param	eventObj A PokerBettingEvent object.
		 */
		private function onBetUpdate(eventObj:PokerBettingEvent):void {
			if (eventObj.sourcePlayer.netCliqueInfo.peerID == this._bettingModule.selfPlayerInfo.netCliqueInfo.peerID) {
				//bet update came from us
				this._currentAmount = eventObj.amount;
				this.updateInterface(eventObj.amount, true);
			} else {
				//external player update
				this.updateInterface(eventObj.amount, false);
			}
		}
		
		/**
		 * Event listener invoked when a player gains or loses betting control.
		 * 
		 * @param	eventObj A PokerBettingEvent object containing information about the current betting player.
		 */
		private function onBettingPlayerUpdate(eventObj:PokerBettingEvent):void {
			if (eventObj.sourcePlayer.netCliqueInfo.peerID != this._bettingModule.selfPlayerInfo.netCliqueInfo.peerID) {				
				this.disableControls(null);
			}
		}
		
		/**
		 * Event listener invoked when the current game is about to be destroyed. This invoked the 'destroy' method.
		 * 
		 * @param	eventObj A PokerGameStatusEvent object.
		 */
		private function onGameDestroy(eventObj:PokerGameStatusEvent):void {
			this.destroy();
		}
	}
}