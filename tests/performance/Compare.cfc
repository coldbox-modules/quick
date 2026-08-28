component {

	function run(
		required string baseline,
		required string candidate,
		numeric maxWallRegressionPercent       = 10,
		numeric maxAllocationRegressionPercent = 10,
		numeric maxRetainedRegressionPercent   = 10,
		boolean failOnRegression               = true
	) {
		var baselinePayload  = deserializeJSON( fileRead( arguments.baseline ) );
		var candidatePayload = deserializeJSON( fileRead( arguments.candidate ) );
		var baselineByName   = indexBenchmarks( baselinePayload.benchmarks );
		var regressions      = [];

		print.line( "Benchmark | wall change | allocation change" );
		for ( var benchmark in candidatePayload.benchmarks ) {
			if ( !baselineByName.keyExists( benchmark.name ) ) {
				continue;
			}
			var previous         = baselineByName[ benchmark.name ];
			var wallChange       = percentChange( previous.wallTime.median, benchmark.wallTime.median );
			var allocationChange = "n/a";
			if ( previous.allocation.supported && benchmark.allocation.supported ) {
				allocationChange = percentChange(
					previous.allocation.summary.median,
					benchmark.allocation.summary.median
				);
			}
			var allocationOutput = isNumeric( allocationChange ) ? formatPercent( allocationChange ) : allocationChange;
			print.line( benchmark.name & " | " & formatPercent( wallChange ) & " | " & allocationOutput );
			if ( wallChange > arguments.maxWallRegressionPercent ) {
				regressions.append( benchmark.name & " wall (" & formatPercent( wallChange ) & ")" );
			}
			if (
				isNumeric( allocationChange ) &&
				allocationChange > arguments.maxAllocationRegressionPercent
			) {
				regressions.append( benchmark.name & " allocation (" & formatPercent( allocationChange ) & ")" );
			}
		}

		var baselineMemoryByName = indexBenchmarks( baselinePayload.memory );
		if ( !candidatePayload.memory.isEmpty() ) {
			print.line( "" );
			print.line( "Retained memory | change" );
		}
		for ( var memoryBenchmark in candidatePayload.memory ) {
			if ( !baselineMemoryByName.keyExists( memoryBenchmark.name ) ) {
				continue;
			}
			var retainedChange = percentChange(
				baselineMemoryByName[ memoryBenchmark.name ].summary.median,
				memoryBenchmark.summary.median
			);
			print.line( memoryBenchmark.name & " | " & formatPercent( retainedChange ) );
			if ( retainedChange > arguments.maxRetainedRegressionPercent ) {
				regressions.append(
					memoryBenchmark.name & " retained memory (" & formatPercent( retainedChange ) & ")"
				);
			}
		}

		if ( arguments.failOnRegression && !regressions.isEmpty() ) {
			throw(
				type    = "PerformanceRegression",
				message = "Wall-time regression threshold exceeded: " & regressions.toList( ", " )
			);
		}
	}

	private struct function indexBenchmarks( required array benchmarks ) {
		var indexed = {};
		for ( var benchmark in arguments.benchmarks ) {
			indexed[ benchmark.name ] = benchmark;
		}
		return indexed;
	}

	private numeric function percentChange( required numeric baseline, required numeric candidate ) {
		return arguments.baseline == 0 ? 0 : ( ( arguments.candidate - arguments.baseline ) / arguments.baseline ) * 100;
	}

	private string function formatPercent( required numeric value ) {
		return ( arguments.value > 0 ? "+" : "" ) & numberFormat( arguments.value, "0.00" ) & "%";
	}

}
