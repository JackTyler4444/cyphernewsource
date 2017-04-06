/**
* Implements an IRoomManager interface as a poker table manager.
*
* (C)opyright 2014 to 2017
*
* This source code is protected by copyright and distributed under license.
* Please see the root LICENSE file for terms and conditions.
*
*/

package org.cg {
	
	import flash.events.Event;
	import org.cg.interfaces.ILounge;
	import p2p3.events.NetCliqueEvent;
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;
	import org.cg.Table;
	import org.cg.interfaces.IRoomProfile;
	import org.cg.events.TableManagerEvent;
	import org.cg.interfaces.IRoom;
	import org.cg.interfaces.IRoomManager;
	import p2p3.interfaces.INetClique;
	import com.hurlant.crypto.hash.SHA256;
	import com.hurlant.util.Hex;
	import p2p3.interfaces.IPeerMessage;
	
	public class TableManager extends EventDispatcher implements IRoomManager {
				
		private var _clique:INetClique = null; //INetClique implementation to be used to create new rooms/tables
		private var _lounge:ILounge = null; //The parent ILounge implementation
		private var _rooms:Vector.<IRoom> = new Vector.<IRoom>(); //rooms being managed by this instance
		private static const _generatedTableIDs:uint = 0; //the number of table IDs generated by this instance, also used when generating new ones
		private var _playerProfile:IRoomProfile = null;
		
		public function TableManager(loungeRef:ILounge) {
			this._lounge = loungeRef;
			if (this._lounge.clique != null) {
				this._clique = this._lounge.clique;
			}
			this.initialize();
			super(this);
		}
		
		public function get profile():IRoomProfile {
			return (this._playerProfile);
		}
		
		public function set profile(profileSet:IRoomProfile):void {
			this._playerProfile = profileSet;
		}
		
		/**
		 * Generates a unique table ID that may be used to create a new table.
		 * 
		 * @param salt An optional salt value to include in the generation of the table ID.
		 * 
		 * @return A unique, generated table ID.
		 */
		public function generateTableID(salt:String = null):String {
			var dateObj:Date = new Date();
			var tID:String = new String();
			if (clique != null) {
				tID = clique.localPeerInfo.peerID;
			}
			tID += String(dateObj.getUTCFullYear())
			if ((dateObj.getUTCMonth()+1) <= 9) {
				tID += "0";
			}
			tID += String((dateObj.getUTCMonth()+1));
			if ((dateObj.getUTCDate()) <= 9) {
				tID += "0";
			}
			tID += String(dateObj.getUTCDate());
			if (dateObj.getUTCHours() <= 9) {
				tID += "0";
			}
			tID += String(dateObj.getUTCHours());
			if (dateObj.getUTCMinutes() <= 9) {
				tID += "0";
			}
			tID += String(dateObj.getUTCMinutes());
			if (dateObj.getUTCSeconds() <= 9) {
				tID += "0";
			}
			tID += String(dateObj.getUTCSeconds());
			if (dateObj.getUTCMilliseconds() <= 9) {
				tID += "0";
			}
			if (dateObj.getUTCMilliseconds() <= 99) {
				tID += "0";
			}
			tID += String(dateObj.getUTCMilliseconds());
			tID += String(_generatedTableIDs);
			if (salt != null) {
				tID += salt;
			}
			var hasher:SHA256 = new SHA256();
			var hexString:String = Hex.fromString(tID, false);
			var tIDBA:ByteArray = Hex.toArray(hexString);
			var output:ByteArray = hasher.hash(tIDBA);
			return (Hex.fromArray(output, false));
		}
		
		private function onPeerConnect(eventObj:NetCliqueEvent):void {
			
		}
		
		private function onPeerMessage(eventObj:NetCliqueEvent):void {
			var peerMsg:TableManagerMessage = TableManagerMessage.validateTableManagerMessage(eventObj.message);						
			if (peerMsg == null) {					
				//not a table manager message
				return;
			}			
			if (eventObj.message.hasSourcePeerID(this.clique.localPeerInfo.peerID)) {
				//already processed by us				
				return;
			}		
			if (eventObj.message.hasTargetPeerID(this.clique.localPeerInfo.peerID)) {
				//message is either specifically for us or for everyone ("*")
				this.processPeerMessage(peerMsg);
			} else {
				//message not intended for us
			}
		}
		
		private function processPeerMessage(peerMsg:TableManagerMessage):void {
			try {
				switch (peerMsg.tableManagerMessageType) {					
					case TableManagerMessage.NEW_TABLE:						
						DebugView.addText ("   TableManagerMessage.NEW_TABLE");
						var tableInfo:Object = peerMsg.data.tableInfo;
						var table:Table = this.newExternalTable(tableInfo);
						if (table != null) {
							this._rooms.push(table as IRoom); //push to "_rooms" not to "tables" (generated vector!)
							var event:TableManagerEvent = new TableManagerEvent(TableManagerEvent.TABLE_RECEIVED);
							event.info = tableInfo;
							event.table = table;
							this.dispatchEvent(event);
						} else {
							//table already exists
						}
						break;
					default: 
						DebugView.addText("   Unrecognized peer message:");
						DebugView.addText(peerMsg);
						break;
				}
			} catch (err:*) {
				//something went wrong processing the message
				DebugView.addText (err.getStackTrace());
			}
		}
		
		private function newExternalTable(tableInfo:Object):Table {
			for (var count:int = 0; count < this.tables.length; count++) {
				if ((this.tables[count].tableID == tableInfo.tableID) && (this.tables[count].ownerPeerID == tableInfo.ownerPeerID)) {
					//table already exists
					return (null);
				}
			}
			try {
				if (tableInfo["requiredPeers"] == undefined) {
					tableInfo.requiredPeers = null;
				}				
				var table:Table = new Table(this, null, tableInfo.requiredPeers);
				table.ownTable = false;
				table.tableID = tableInfo.tableID;
				table.ownerPeerID = tableInfo.ownerPeerID;
				table.currentDealerPeerID = tableInfo.currentDealerPeerID;
				table.numPlayers = tableInfo.numPlayers;
				if (tableInfo.requiredPeers != null) {
					if (tableInfo.requiredPeers.length > 0) {
						table.numPlayers = tableInfo.requiredPeers.length;
					}
				}				
				table.isOpen = tableInfo.isOpen;
				table.smartContractAddress = tableInfo.smartContractAddress;
				table.currencyUnits = tableInfo.currencyUnits;
				table.buyInAmount = tableInfo.buyInAmount;
				table.smallBlindAmount = tableInfo.smallBlindAmount;
				table.bigBlindAmount = tableInfo.bigBlindAmount;
				table.blindsTime = tableInfo.blindsTime;
				return (table);
			} catch (err:*) {
			}
			return (null);
		}
		
		/**
		 * Sets up all variables and references for a new instance. All existing ones are cleared.
		 */
		private function initialize():void {
			this._rooms = new Vector.<IRoom>();
			if (this._clique != null) {
				this._clique.removeEventListener(NetCliqueEvent.CLIQUE_DISCONNECT, this.onCliqueDisconnect);
				this._clique.removeEventListener(NetCliqueEvent.PEER_CONNECT, this.onPeerConnect);
				this._clique.removeEventListener(NetCliqueEvent.PEER_MSG, this.onPeerConnect);
				this._clique.addEventListener(NetCliqueEvent.CLIQUE_DISCONNECT, this.onCliqueDisconnect);
				this._clique.addEventListener(NetCliqueEvent.PEER_CONNECT, this.onPeerConnect);
				this._clique.addEventListener(NetCliqueEvent.PEER_MSG, this.onPeerMessage);
			}
		}
		
		private function onCliqueDisconnect(eventObj:NetCliqueEvent):void {
			this.destroy();
			var event:TableManagerEvent = new TableManagerEvent(TableManagerEvent.DISCONNECT);
			this.dispatchEvent(event);
		}
		
		/**
		 * Creates a Table with its own segregated clique.
		 * 
		 * @param	cliqueOptions Optional options object to send to the current INetClique implementation's "newRoom" method. If omitted (not recommended),
		 * the table will use the default clique options of the "newRoom" method.
		 * @param requiredPeers An optional list of peers that are required to connect before a table is considered fully occupied and peers not on the list
		 * will not register as valid peers in the target Table instance. If this value is omitted, null, or has a length of 0, then the table is an open one and 
		 * the first connecting peer will trigger the TableEvent.OCCUPIED event.
		 * @param tableOptions Optional options to assign to the new table instance. Properties in the object should match publicly accessible properties
		 * in the new Table instance. These properties may also be assigned directly to the newly created table instance.
		 * @param autoJoin If true a new clique instance is automatically created and joined, otherwise the returned table instance must be joined manually.
		 * 
		 * @return The new Table instance with a segragated clique. If the table with the specified options already exists then its segregated 
		 * clique is joined.
		 */
		public function newTable(cliqueOptions:Object = null, requiredPlayers:Array = null, tableOptions:Object = null, autoJoin:Boolean = false):Table {
			if (autoJoin) {
				var newClique:INetClique = this._clique.newRoom(cliqueOptions);
			} else {
				newClique = null;
			}
			var table:Table = new Table(this, newClique, requiredPlayers);
			table.ownTable = true;
			this._rooms.push(table as IRoom);
			if (tableOptions != null) {
				for (var currentOption:String in tableOptions) {
					try {
						table[currentOption] = tableOptions[currentOption];
					} catch (err:*) {
						DebugView.addText ("Problem assigning property \""+currentOption+"\" to new Table instance");
					}
				}
			}
			var event:TableManagerEvent = new TableManagerEvent(TableManagerEvent.NEW_TABLE);
			event.table = table;			
			this.dispatchEvent(event);
			return (table);
		}
		
		/**
		 * Enables new table announcement beacons / messages for any tables created by the local (self) player.
		 */
		public function enableTableBeacons():void {
			for (var count:int = 0; count < this.tables.length; count++) {
				this.tables[count].enableAnnounceBeacon();
			}
		}
		
		/**
		 * Disables new table announcement beacons / messages for any tables created by the local (self) player.
		 */
		public function disableTableBeacons():void {
			for (var count:int = 0; count < this.tables.length; count++) {
				this.tables[count].disableAnnounceBeacon();
			}
		}
		
		public function announceTable(tableInstance:Table):void {
			var payload:Object = new Object();
			payload.tableInfo = tableInstance.createTableInfoObject();			
			var msg:TableManagerMessage = new TableManagerMessage();
			msg.createTableManagerMessage(TableManagerMessage.NEW_TABLE, payload);
			msg.targetPeerIDs = "*"; //send to everyone
			this.clique.broadcast(msg);
		}
		
		public function get tables():Vector.<Table> {
			var returnTables:Vector.<Table> = new Vector.<Table>();
			for (var count:int = 0; count < this._rooms.length; count++) {
				returnTables.push(this._rooms[count] as Table);
			}
			return (returnTables);
		}
		
		public function get lounge():ILounge {
			return (this._lounge);
		}
		
		public function set clique(cliqueRef:INetClique):void {			
			var preset:INetClique = this._clique;
			this._clique = cliqueRef;
			if (preset != this._clique) {
				this.initialize();
			}
		}
		
		public function get clique():INetClique {
			return (this._clique);
		}
		
		public function get rooms():Vector.<IRoom> {
			return (this._rooms);
		}
		
		public function destroy():void {			
			if (this._rooms!=null) {
				for (var count:int = 0; count < this._rooms.length; count++) {
					this._rooms[count].destroy();
				}
			}
			if (this._clique != null) {
				this._clique.removeEventListener(NetCliqueEvent.CLIQUE_DISCONNECT, this.onCliqueDisconnect);
				this._clique.removeEventListener(NetCliqueEvent.PEER_CONNECT, this.onPeerConnect);
				this._clique.removeEventListener(NetCliqueEvent.PEER_MSG, this.onPeerConnect);
			}
			this._rooms = null;
		}
	}
}