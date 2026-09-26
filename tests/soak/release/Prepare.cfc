component {

	property name="parser"         inject="ConventionalChangelogParser@commandbox-semantic-release";
	property name="filterer"       inject="DefaultCommitFilterer@commandbox-semantic-release";
	property name="analyzer"       inject="DefaultCommitAnalyzer@commandbox-semantic-release";
	property name="notesGenerator" inject="GitHubMarkdownNotesGenerator@commandbox-semantic-release";
	property name="releaseMarker"  inject="commandbox:moduleSettings:commandbox-semantic-release:buildCommitMessage";
	property name="fileSystemUtil" inject="FileSystem";

	// Read-only semantic-release preparation. No updater, committer, publisher,
	// publicizer or condition verifier is instantiated or called by this task.
	function run( required string input, required string output ) {
		if ( releaseMarker != "__SEMANTIC RELEASE VERSION UPDATE__" ) {
			throw( type = "SoakPreparation", message = "Semantic-release version-update skip marker differs" );
		}
		var pluginRoot = createObject( "java", "java.io.File" )
			.init( getDirectoryFromPath( getMetadata( variables.parser ).path ) & "../.." )
			.getCanonicalPath() & "/";
		var descriptor = deserializeJSON( fileRead( pluginRoot & "box.json" ) );
		if ( descriptor.version != "4.1.0" ) {
			throw( type = "SoakPreparation", message = "Semantic-release 4.1.0 is required" );
		}
		var pluginFiles = {};
		for ( var path in directoryList( pluginRoot, true, "path", "*.cfc" ) ) {
			pluginFiles[ replace( path, pluginRoot, "" ) ] = lCase( hash( fileReadBinary( path ), "SHA-256" ) );
		}
		pluginFiles[ "box.json" ] = lCase( hash( fileReadBinary( pluginRoot & "box.json" ), "SHA-256" ) );
		var preparation           = deserializeJSON( fileRead( arguments.input ) );
		if ( !reFind( "^[0-9]+\.[0-9]+\.[0-9]+$", preparation.lastRelease.version ) ) {
			throw( type = "SoakPreparation", message = "Only stable release preparation is qualified" );
		}
		if ( fileExists( arguments.output ) ) {
			throw( type = "SoakPreparation", message = "Preparation output already exists" );
		}
		var builder    = createObject( "java", "org.eclipse.jgit.storage.file.FileRepositoryBuilder" ).init();
		var repository = builder
			.setGitDir( createObject( "java", "java.io.File" ).init( fileSystemUtil.resolvePath( "" ) & ".git" ) )
			.setMustExist( true )
			.build();
		var walk = createObject( "java", "org.eclipse.jgit.revwalk.RevWalk" ).init( repository );
		try {
			// Exact commits supplied by the wrapper; never walk a moving branch.
			var commits = preparation.commitShas.map( function( sha ) {
				return parser.run(
					walk.parseCommit( repository.resolve( sha ) ),
					true,
					false
				);
			} );
			commits    = filterer.run( commits, true, false );
			var result = {
				"candidateSha"           : preparation.candidateSha,
				"lastRelease"            : preparation.lastRelease,
				"preparedAt"             : preparation.preparedAt,
				"semanticReleaseVersion" : descriptor.version,
				"semanticReleaseFiles"   : pluginFiles,
				"noRelease"              : arrayIsEmpty( commits )
			};
			if ( !result.noRelease ) {
				var type  = analyzer.run( commits, true, false );
				var parts = listToArray( preparation.lastRelease.version, "." );
				if ( type == "major" ) {
					if ( val( parts[ 1 ] ) == 0 ) {
						parts[ 2 ]++;
					} else {
						parts[ 1 ]++;
						parts[ 2 ] = 0;
					}
					parts[ 3 ] = 0;
				} else if ( type == "minor" ) {
					if ( val( parts[ 1 ] ) == 0 ) {
						parts[ 3 ]++;
					} else {
						parts[ 2 ]++;
						parts[ 3 ] = 0;
					}
				} else if ( type == "patch" ) {
					parts[ 3 ]++;
				} else {
					throw( type = "SoakPreparation", message = "Unsupported release type" );
				}
				result[ "version" ]     = arrayToList( parts, "." );
				result[ "releaseType" ] = type;
				result[ "notes" ]       = "## v" & result.version & chr( 10 ) & "#### " &
				dateTimeFormat(
					preparation.preparedAt,
					'dd mmm yyyy ''—'' HH:nn:ss ''UTC''',
					"UTC"
				) & chr( 10 ) & chr( 10 ) & notesGenerator.run(
					preparation.lastRelease.version,
					result.version,
					commits,
					type,
					preparation.repositoryURL,
					true,
					false
				);
				result[ "commits" ] = commits.map( function( commit ) {
					return commit.hash;
				} );
			}
			fileWrite( arguments.output, serializeJSON( result ) );
		} finally {
			walk.close();
			repository.close();
		}
	}

}
