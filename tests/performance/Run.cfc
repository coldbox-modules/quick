component {

	function run(
		string url              = "http://127.0.0.1:60299/tests/performance/runner.cfm",
		numeric warmup          = 5,
		numeric samples         = 9,
		numeric iterations      = 25,
		numeric databaseRows    = 1000,
		numeric retainedItems   = 250,
		boolean includeDatabase = true,
		boolean includeRetained = true,
		string only             = "",
		string output           = "tests/results/performance-latest.json"
	) {
		var targetUrl = arguments.url & "?" & [
			"warmup=#urlEncodedFormat( arguments.warmup )#",
			"samples=#urlEncodedFormat( arguments.samples )#",
			"iterations=#urlEncodedFormat( arguments.iterations )#",
			"databaseRows=#urlEncodedFormat( arguments.databaseRows )#",
			"retainedItems=#urlEncodedFormat( arguments.retainedItems )#",
			"includeDatabase=#urlEncodedFormat( arguments.includeDatabase )#",
			"includeRetained=#urlEncodedFormat( arguments.includeRetained )#",
			"only=#urlEncodedFormat( arguments.only )#"
		].toList( "&" );

		cfhttp(
			url          = targetUrl,
			method       = "GET",
			timeout      = 900,
			throwOnError = false,
			result       = "local.response"
		);

		var statusCode = response.keyExists( "status_code" ) ? val( response.status_code ) : val( response.statusCode );
		if ( statusCode < 200 || statusCode >= 300 ) {
			throw(
				type    = "PerformanceRunnerRequestFailed",
				message = "Benchmark endpoint [#targetUrl#] returned HTTP #response.statusCode#.",
				detail  = response.fileContent
			);
		}

		var payload = deserializeJSON( response.fileContent );
		if ( payload.keyExists( "error" ) && payload.error ) {
			throw(
				type    = payload.type,
				message = payload.message,
				detail  = payload.detail
			);
		}

		if ( len( arguments.output ) ) {
			var outputDirectory = getDirectoryFromPath( arguments.output );
			if ( len( outputDirectory ) && !directoryExists( outputDirectory ) ) {
				directoryCreate( outputDirectory, true );
			}
			fileWrite( arguments.output, serializeJSON( payload ) );
		}

		if ( !payload.errors.isEmpty() ) {
			var benchmarkErrors = [];
			for ( var benchmarkError in payload.errors ) {
				benchmarkErrors.append(
					benchmarkError.category & ": " & benchmarkError.type & " - " & benchmarkError.message
				);
			}
			throw(
				type    = "PerformanceBenchmarkErrors",
				message = "One or more requested benchmark groups failed: " & benchmarkErrors.toList( "; " )
			);
		}

		print.line( "Quick performance benchmark complete" );
		print.line( "Engine: #payload.environment.engine.name# #payload.environment.engine.version#" );
		print.line( "Duration: #payload.durationMs# ms" );
		for ( var benchmark in payload.benchmarks ) {
			var allocation = benchmark.allocation.supported
			 ? numberFormat( benchmark.allocation.summary.median, "0.00" ) & " B/op"
			 : "allocation unavailable";
			print.line(
				"#benchmark.name#: #numberFormat( benchmark.wallTime.median / 1000, "0.00" )# us/op, #allocation#"
			);
		}
		if ( len( arguments.output ) ) {
			print.line( "JSON: #arguments.output#" );
		}
	}

}
