component {

	this.name               = "quick-soak-" & hash( getCurrentTemplatePath() );
	this.applicationTimeout = createTimespan( 0, 4, 0, 0 );
	this.sessionManagement  = false;
	this.setClientCookies   = false;
	this.nullSupport        = true;
	this.timezone           = "UTC";
	this.datasource         = "quick_soak";
	this.serialization      = { preserveCaseForStructKey : true };
	this.datasources        = {
		quick_soak : {
			class            : "com.mysql.cj.jdbc.Driver",
			bundleName       : "com.mysql.cj",
			bundleVersion    : "8.0.33",
			connectionString : "jdbc:mysql://" & env( "SOAK_DB_HOST", "127.0.0.1" ) & ":" & env(
				"SOAK_DB_PORT",
				"33316"
			) & "/quick_soak?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC",
			username          : "quick_soak",
			password          : env( "SOAK_DB_PASSWORD", "quick_soak" ),
			connectionLimit   : val( env( "SOAK_DB_POOL_LIMIT", "16" ) ),
			connectionTimeout : 1,
			liveTimeout       : 120,
			validate          : true
		}
	};

	private string function env( required string name, string fallback = "" ) {
		return server.system.environment[ arguments.name ] ?: arguments.fallback;
	}

	boolean function onApplicationStart() {
		// JVM-scoped counter survives application reloads without retaining any request data.
		lock name="quick-soak-start-counter" type="exclusive" timeout=10 {
			if ( !structKeyExists( server, "quickSoakStarts" ) ) {
				server.quickSoakStarts = createObject( "java", "java.util.concurrent.atomic.AtomicLong" ).init( 0 );
			}
			application.soakStartCount = server.quickSoakStarts.incrementAndGet();
		}
		application.soakBootId       = createUUID();
		application.soakFaultMode    = env( "SOAK_FAULT_MODE", "none" );
		application.soakFaultStarted = 0;
		if ( !listFind( "none,held-connection,wrong-contract,latency,late-latency", application.soakFaultMode ) ) {
			throw( type = "SoakConfiguration", message = "Unknown controlled fault" );
		}
		application.soakErrors = {};
		for (
			var label in [
				"missing_pk",
				"empty_lookup",
				"relationship",
				"invalid_write",
				"rollback",
				"post_delete",
				"unexpected"
			]
		) {
			application.soakErrors[ label ] = createObject( "java", "java.util.concurrent.atomic.AtomicLong" ).init( 0 );
		}
		application.soakToken = env( "SOAK_TOKEN" );
		if ( len( application.soakToken ) < 32 ) {
			throw( type = "SoakConfiguration", message = "SOAK_TOKEN must contain at least 32 characters." );
		}
		application.cbBootstrap = new coldbox.system.Bootstrap( "", getDirectoryFromPath( getCurrentTemplatePath() ) );
		application.cbBootstrap.loadColdBox();
		return true;
	}

	boolean function onRequestStart( string targetPage ) {
		setting requestTimeout=15;
		var headers           = getHTTPRequestData( false ).headers;
		if (
			!structKeyExists( headers, "X-Soak-Token" ) || compare( headers[ "X-Soak-Token" ], application.soakToken ) != 0
		) {
			cfheader( statusCode = 401 );
			cfcontent( type = "application/json", reset = true );
			writeOutput( '{"error":{"code":"Unauthorized"}}' );
			return false;
		}
		application.cbBootstrap.onRequestStart( arguments.targetPage );
		return true;
	}

	void function onApplicationEnd( struct appScope ) {
		arguments.appScope.cbBootstrap.onApplicationEnd( arguments.appScope );
	}

	boolean function onMissingTemplate( string template ) {
		return application.cbBootstrap.onMissingTemplate( argumentCollection = arguments );
	}

}
