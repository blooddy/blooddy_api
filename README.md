Examples
--------
```actionscript

import by.blooddy.api.desktop.VK;

var vk:VK = new VK( {
	username:	'username',
	password:	'password',
	scope:		'groups,audio,status',
	api_id:		api_id
} );


vk.query(
	'audio.get', { owner_id: -34963172 },
	function(result:Object):void {
		trace( result );
	},
	function(e:Error):void {
		trace( e );
	}
);

```