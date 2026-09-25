component {

	function configure() {
		coldbox = {
			appName                 : "Quick release soak",
			reinitPassword          : createUUID(),
			handlersIndexAutoReload : false,
			handlerCaching          : true,
			eventCaching            : false,
			viewCaching             : false,
			exceptionHandler        : "Api.onException",
			customErrorTemplate     : "/views/error.cfm"
		};
		flash = {
			scope        : "coldbox.system.web.flash.ColdboxCacheFlash",
			autoPurge    : false,
			autoSave     : false,
			inflateToRC  : false,
			inflateToPRC : false
		};
		modules        = { autoReload : false };
		moduleSettings = {
			quick : {
				defaultGrammar       : "MySQLGrammar@qb",
				parallelEagerLoading : false
			},
			mementifier : { convertToTimezone : "UTC" }
		};
		logBox = {
			appenders : {
				soak : {
					class      : "coldbox.system.logging.appenders.RollingFileAppender",
					properties : {
						filePath        : expandPath( "/logs" ),
						autoExpand      : false,
						filename        : "soak",
						fileMaxSize     : 2048,
						fileMaxArchives : 3
					}
				}
			},
			root : { levelMax : "WARN", appenders : "*" }
		};
	}

}
