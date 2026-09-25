/** Creates deterministic fixtures once in an explicitly named disposable container. */
component {

	function run( required string container, required string output ) {
		if ( !reFind( "^quick-soak-[a-z0-9-]+$", arguments.container ) ) {
			throw( type = "SoakUnsafeDatabase", message = "Only explicitly named quick-soak-* containers are allowed." );
		}
		var destinationFile = createObject( "java", "java.io.File" ).init( arguments.output );
		var destination     = destinationFile.isAbsolute()
		 ? destinationFile.getCanonicalPath()
		 : createObject( "java", "java.io.File" )
			.init( getDirectoryFromPath( getCurrentTemplatePath() ) & "../../" & arguments.output )
			.getCanonicalPath();
		var generator = getDirectoryFromPath( getCurrentTemplatePath() ) & "fixtures/generate.py";
		execute( [ "python3", generator, destination ] );
		// Password is passed by environment; neither shell interpolation nor command echo is used.
		var password = systemSettings.getSystemSetting( "SOAK_MYSQL_ROOT_PASSWORD", "" );
		if ( !len( password ) ) {
			throw( type = "SoakConfiguration", message = "SOAK_MYSQL_ROOT_PASSWORD is required." );
		}
		execute(
			[
				"docker",
				"exec",
				"-i",
				"-e",
				"MYSQL_PWD",
				arguments.container,
				"mysql",
				"-uroot"
			],
			fileReadBinary( destination & "/seed.sql" ),
			{ "MYSQL_PWD" : password }
		);
		print.greenLine( "Seeded quick_soak once. Fixture manifest: " & destination & "/fixture-manifest.json" );
	}

	private void function execute(
		required array command,
		any input,
		struct environment = {}
	) {
		var builder = createObject( "java", "java.lang.ProcessBuilder" ).init(
			javacast( "string[]", arguments.command )
		);
		builder.redirectErrorStream( true );
		for ( var key in arguments.environment ) {
			builder.environment().put( key, arguments.environment[ key ] );
		}
		// Output is bounded: generator prints only fixture summary; MySQL prints only errors.
		var process = builder.start();
		if ( !isNull( arguments.input ) ) {
			process.getOutputStream().write( arguments.input );
		}
		process.getOutputStream().close();
		var text     = charsetEncode( process.getInputStream().readAllBytes(), "UTF-8" );
		var exitCode = process.waitFor();
		if ( exitCode != 0 ) {
			throw(
				type    = "SoakSetupFailed",
				message = "Fixture setup failed",
				detail  = left( text, 4000 )
			);
		}
	}

}
