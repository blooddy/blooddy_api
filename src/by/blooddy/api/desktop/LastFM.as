package by.blooddy.api.desktop {
	
	import flash.events.Event;
	import flash.events.HTMLUncaughtScriptExceptionEvent;
	import flash.html.HTMLLoader;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	
	import by.blooddy.api.LastFM;
	
	/**
	 * @author					BlooDHounD
	 * @version					1.0
	 * @playerversion			Flash 10
	 * @langversion				3.0
	 */
	public class LastFM extends by.blooddy.api.LastFM {
		
		//--------------------------------------------------------------------------
		//
		//  Constructor
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Constructor
		 */
		public function LastFM(parameters:Object) {
			
			super( parameters );
			
			this._username =	parameters[ 'username' ];
			this._password =	parameters[ 'password' ];
			
			if ( !this._sk || !this._token ) {
				super.auth();
			}
			
		}
		
		//--------------------------------------------------------------------------
		//
		//  Variables
		//
		//--------------------------------------------------------------------------
		
		private var _username:String;
		private var _password:String;
		
		//--------------------------------------------------------------------------
		//
		//  Methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * @inheritDoc
		 */
		public override function query(method:String, params:Object=null, success:Function=null, fail:Function=null):void {
			
			var auth:Function = super.auth;
			var query:Function = super.query;
			
			super.query( method, params, success, function(e:Error):void {
				switch ( e.errorID ) {
					
					case 4:
					case 6:
					case 9:
					case 14:
						auth( function():void {
							query( method, params, success, fail );
						}, fail );
						break;
					
					default:
						if ( fail ) fail( e );
						break;
					
				}
			} );
			
		}
		
		//--------------------------------------------------------------------------
		//
		//  Protected methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * @private
		 */
		protected override function auth_api(success:Function, fail:Function):void {
			
			var lastFM:by.blooddy.api.desktop.LastFM = this;
			
			setKey( 'token', lastFM._token = null );
			setKey( 'sk', lastFM._sk = null );
			
			super.query(
				'auth.getToken', null,
				function(result:Object):void {
					
					if ( result.token ) {
						
						setKey( 'token', lastFM._token = result.token );
						
						var data:URLVariables = new URLVariables();
						data = new URLVariables();
						data.api_key = lastFM._api_key;
						data.token = lastFM._token;
						
						var request:URLRequest = new URLRequest();
						request.url = 'http://www.last.fm/api/auth';
						request.data = data;
						
						var html:HTMLLoader = new HTMLLoader();
						html.load( request );
						html.addEventListener( HTMLUncaughtScriptExceptionEvent.UNCAUGHT_SCRIPT_EXCEPTION, function(event:Event):void {} );
						html.addEventListener( Event.HTML_DOM_INITIALIZE, function domInitialize(event:Event):void {
							
							if ( html.parent ) html.parent.removeChild( html );
							
							function cancel():void {
								if ( html.parent ) html.parent.removeChild( html );
								html.removeEventListener( Event.HTML_DOM_INITIALIZE, domInitialize );
								html.cancelLoad();
							}
							
							var document:Object = html.window.document;
							
							if ( /^https?:\/\/secure\.last\.fm\/login/.test( html.window.location ) ) {
								
								document.addEventListener( 'DOMContentLoaded', function domLoaded(event:Object):void {
									document.removeEventListener( 'DOMContentLoaded', domLoaded );
									
									try {
										var form:Object = document.querySelector( 'form[action$="/login"]' );
										form.username.value = lastFM._username;
										form.password.value = lastFM._password;
										document.createElement( 'form' ).submit.call( form );
									} catch ( e:Error ) {
										if ( fail ) fail( e );
										cancel();
									}
									
								} );
								
							} else if ( /https?:\/\/(www\.)?last\.fm\/api\/auth/.test( html.window.location ) ) {
								
								document.addEventListener( 'DOMContentLoaded', function domLoaded(event:Object):void {
									document.removeEventListener( 'DOMContentLoaded', domLoaded );
									
									if ( !document.querySelector( 'a[href="/user/' + lastFM._username + '"] img[alt="' + lastFM._username + '"]' ) ) {
											
										try {
											var form:Object = document.querySelector( 'form[action$="/logout"]' );
											document.createElement( 'form' ).submit.call( form );
										} catch ( e:Error ) {
											if ( fail ) fail( e );
											cancel();
										}
										
									} else {
											
										html.removeEventListener( Event.HTML_DOM_INITIALIZE, domInitialize );
										
										try {
											
											var input:Object = document.querySelector( 'form input[type="hidden"][name="submit"][value="confirm"]' );
											document.createElement( 'form' ).submit.call( input.form );
											
											html.addEventListener( Event.HTML_DOM_INITIALIZE, function domInitializeFinish(event:Event):void {
												html.removeEventListener( Event.HTML_DOM_INITIALIZE, domInitializeFinish );
												html.cancelLoad();
												
												lastFM.query(
													'auth.getSession', null,
													function(result:Object):void {
														try {
															
															if ( !result.session.key ) throw new Error( 'unknown session' );
															
															setKey( 'sk', lastFM._sk = result.session.key );
															
															if ( success ) success();
															
														} catch ( e:Error ) {
															if ( fail ) fail( e );
														}
													},
													function(e:Error):void {
														if ( fail ) fail( e );
													}
												);
												
											} );
											
										} catch ( e:Error ) {
											if ( fail ) fail( e );
											cancel();
										}
										
									}
									
								} );
								
							} else {
								
								lastFM.accept( html, function(e:Error):void {
									
									if ( fail ) fail( e );
									cancel();
									
								} );
								
							}
							
						} );
						
					} else {
						
						if ( fail ) fail( new VerifyError() );
						
					}
					
				},
				fail
			);
			
		}
		
	}
	
}