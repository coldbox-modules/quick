component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

	function run() {
		describe( "Entity Creation", function() {
			it( "entity creation should take less than 1ms on average", function() {
				var numEntities = 100;
				var times       = [];
				var last        = microsecondsTickCount();
				for ( var i = 1; i <= numEntities; i++ ) {
					getInstance( "User" );
					var now = microsecondsTickCount();
					times.append( now - last );
					last = now;
				}
				arrayDeleteAt( times, 1 ); // ignore the first one.  WireBox and Quick are both booting up there.
				var averageDurationInMicroseconds = times.sum() / times.len();
				var averageDuration               = averageDurationInMicroseconds / 1000;
				debug( "Average duration: #averageDuration# ms" );
				debug( times );
			} );

			it( "can retrieve 1000 records", function() {
				queryExecute( "TRUNCATE TABLE `a`" );
				for ( var i = 1; i <= 1000; i++ ) {
					// create A
					var a = queryExecute( "INSERT INTO `a` (`name`) VALUES (?)", [ "Instance #i#" ] );
				}
				var start   = microsecondsTickCount();
				var records = getInstance( "A" ).get();
				var end     = microsecondsTickCount();
				debug( "Duration: #( end - start ) / 1000# ms" );
				expect( records ).toHaveLength( 1000 );
			} );
		} );
	}

	function microsecondsTickCount() {
		param variables.javaSystem = createObject( "java", "java.lang.System" );
		return variables.javaSystem.nanoTime() / 1000;
	}

}
