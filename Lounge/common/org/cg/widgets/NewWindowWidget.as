/**
* Used to launch a new application window with its own, isolated lounge.
*
* (C)opyright 2014 to 2017
*
* This source code is protected by copyright and distributed under license.
* Please see the root LICENSE file for terms and conditions.
*
*/
package org.cg.widgets {
	
	import org.cg.interfaces.ILounge;
	import org.cg.interfaces.IPanelWidget;
	import org.cg.SlidingPanel;
	import starling.events.Event;
	import feathers.controls.Button;
	import org.cg.DebugView;
	import org.cg.GlobalSettings

	public class NewWindowWidget extends PanelWidget implements IPanelWidget {
		
		//UI rendered by StarlingViewManager:
		public var openNewWindowButton:Button;
				
		/**
		 * Creates a new instance.
		 * 
		 * @param	loungeRef A reference to the main ILounge implementation instance.
		 * @param	panelRef The widget's parent panel or display object container.
		 * @param	widgetData The widget's configuration XML data, usually from the global settings data.
		 */
		public function NewWindowWidget(loungeRef:ILounge, panelRef:SlidingPanel, widgetData:XML) {
			DebugView.addText("NewWindowWidget created");
			super(loungeRef, panelRef, widgetData);
		}
		
		/**
		 * Initializes the widget after it's been added to the display list and when its components have been rendered.
		 */
		override public function initialize():void {
			DebugView.addText("NewWindowWidget.initialize");
			this.openNewWindowButton.addEventListener(Event.TRIGGERED, this.onOpenNewWindowClick);
			super.initialize();
			/// look for user requested additional windown
			/// instances
			try {
				DebugView.addText("Check for user requested new window instances.");
				var openNewWindowIsEnabled:XML = GlobalSettings.getSetting("defaults", "opennewwindow");
				var openNewWindowIsEnabledBool:Boolean = Boolean(openNewWindowIsEnabled);
				//var enabledchild:XML = openNewWindowIsEnabled.child("enabled")[0];
			} catch (err:*) {        
				//break?
				DebugView.addText("No user requests detected for new windows.");
			}          
			if (openNewWindowIsEnabledBool == true) {
				
				if (lounge.isChildInstance) {
					//this is a new window
				} 
				
				else {
					
					DebugView.addText("New window requested in default settings. Opening new window.");
				
				
				//var startupenabled:XML = GlobalSettings.getSetting("defaults", "opennewwindow").enabled;
				//var enabledchild:XML = startupenabled.child("enabled")[0];
				//enabledchild.replace("*", new XML("false"));
				
					//openNewWindowIsEnabled.enabled.replace("*", new XML("false"));
					//var testheck:Boolean = GlobalSettings.saveSettings();
				
				//DebugView.addText("Settings saved : " + testheck);
				
				//startupenabled.replace("*", "false");
				//GlobalSettings.saveSettings();
				
					//DebugView.addText("Updated Settings: " + openNewWindowIsEnabled.enabled);
				
					onOpenNewWindowClick(null);
				
				//openNewWindowIsEnabled.enabled.replace("*", new XML("true"));
				//GlobalSettings.saveSettings();
				
				//enabledchild.replace("*", new XML("true"));
				//GlobalSettings.saveSettings();
				
				//DebugView.addText("Updated Settings 2: " + openNewWindowIsEnabled.enabled);
				}
				
				
			}   
		}
		
		/**
		 * Event listener invoked when the "open new window" button is clicked. This opens a new application window
		 * using the main lounge's 'launchNewLounge' method.
		 * 
		 * @param	eventObj An Event object.
		 */
		private function onOpenNewWindowClick(eventObj:Event):void {
			
			//var startupenabledtest:XML = GlobalSettings.getSetting("defaults", "opennewwindow").enabled;
				
			//startupenabledtest.replace("*", "false");
			//GlobalSettings.saveSettings();
				
			lounge.launchNewLounge();
			
			//startupenabledtest.replace("*", "true");
			//GlobalSettings.saveSettings();
		}		
	}
}