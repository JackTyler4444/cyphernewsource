package org.cg.widgets 
{
	import org.cg.interfaces.ILounge;
	import org.cg.interfaces.IPanelWidget;
	import org.cg.SlidingPanel;
	import starling.events.Event;
	import feathers.controls.TextInput;
	import feathers.controls.Button;
	import org.cg.interfaces.IWidget;
	
	/**import org.cg.DebugView;*/
	
	/**
	 * ...
	 * @author ...
	 */
	public class EtherTransferWidget extends PanelWidget implements IPanelWidget 
	{
		public var sendEtherButton:Button;
		public var clearButton:Button;
		public var etherTransferAmount:TextInput;
		public var recieverAddress:TextInput;
		public var transactionOutput:TextInput;
		
		public function EtherTransferWidget(loungeRef:ILounge, panelRef:SlidingPanel, widgetData:XML) 
		{
			/**DebugView.addText ("EtherTransferWidget created");*/
			super(loungeRef, panelRef, widgetData);
			
		}
		
		 private function onSendEtherClick(event:Event):void {
			/**DebugView.addText ("EtherTransferWidget.onSendEtherClick"); */
			/** Needs to throw to errof if client isn't enabled */
			if (lounge.ethereum != null) {
				//ethereum is available
				var fromAddr:String = this.lounge.ethereum.account;
				var password:String = this.lounge.ethereum.password;
				var toAddr:String = this.recieverAddress.text;
				var etherAmount:Number = Number(this.etherTransferAmount.text);
			
				if (isNaN(etherAmount)) {
					this.transactionOutput.text = "Error: Please Enter Amount of Eth To Send";
				}
				else {
					var etherAmountString:String = etherAmount.toString();
					var weiAmount:String = this.lounge.ethereum.web3.toWei(etherAmountString, "ether");
					var accountUnlocked:Boolean = this.lounge.ethereum.unlockAccount();
					
					if  (accountUnlocked == false) {
						this.transactionOutput.text = "Error: Account Locked";
					}
					else {
						var txHashOutput:String = this.lounge.ethereum.client.lib.sendTransaction(fromAddr, toAddr, weiAmount, password);
						this.transactionOutput.text = "Sent " + etherAmountString  + " eth. txHash: " + txHashOutput;
					}
				}		
			}
			else {
				//ethereum is NOT available throw an error
				this.transactionOutput.text = "No Ethereum Client Enabled!"
			}	
		}
		
		private function onClearClick(event:Event):void {
			this.recieverAddress.text = "Enter Reciever's Address";
			this.etherTransferAmount.text = "Eth";
			this.transactionOutput.text = "Transaction Hash Return";
			
			var matchingWidgets:Vector.<IWidget> = getInstanceByClass("org.cg.widgets.EthereumAccountWidget");
			var ethAccountWidget:EthereumAccountWidget = matchingWidgets[0] as EthereumAccountWidget;
			var accountTemp:Boolean = false; 
			
			ethAccountWidget.unlockAccountStatus(accountTemp);
		}
	 
		override public function initialize():void {
			/**DebugView.addText ("EtherTransferWidget initialize");*/
			 this.sendEtherButton.addEventListener(Event.TRIGGERED, this.onSendEtherClick);
			 this.clearButton.addEventListener(Event.TRIGGERED, this.onClearClick);
		}
	
	}

}