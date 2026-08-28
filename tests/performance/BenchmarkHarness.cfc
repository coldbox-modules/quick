component {

	public any function init(
		numeric warmupIterations = 5,
		numeric samples          = 9,
		numeric iterations       = 25
	) {
		variables.defaultWarmupIterations = arguments.warmupIterations;
		variables.defaultSamples          = arguments.samples;
		variables.defaultIterations       = arguments.iterations;
		variables.system                  = createObject( "java", "java.lang.System" );
		variables.runtime                 = createObject( "java", "java.lang.Runtime" ).getRuntime();
		variables.thread                  = createObject( "java", "java.lang.Thread" ).currentThread();
		variables.threadId                = variables.thread.getId();
		variables.threadBean              = createObject( "java", "java.lang.management.ManagementFactory" ).getThreadMXBean();
		variables.cpuTimeSupported        = configureCpuTime();
		variables.allocationSupported     = configureAllocationTracking();
		variables.blackhole               = 0;
		return this;
	}

	/**
	 * Measures repeated invocations of a callback after an untimed warmup.
	 * The callback should return a value so the work remains observable to the JVM.
	 */
	public struct function measure(
		required string name,
		required any callback,
		string category                = "general",
		numeric operationsPerIteration = 1,
		numeric warmupIterations       = variables.defaultWarmupIterations,
		numeric samples                = variables.defaultSamples,
		numeric iterations             = variables.defaultIterations,
		string description             = ""
	) {
		guardPositive( "operationsPerIteration", arguments.operationsPerIteration );
		guardPositive( "samples", arguments.samples );
		guardPositive( "iterations", arguments.iterations );
		if ( arguments.warmupIterations < 0 ) {
			throw( type = "InvalidBenchmarkConfiguration", message = "warmupIterations must be zero or greater." );
		}

		for ( var warmupIndex = 1; warmupIndex <= arguments.warmupIterations; warmupIndex++ ) {
			consume( arguments.callback( warmupIndex ) );
		}

		var wallTimeSamples     = [];
		var cpuTimeSamples      = [];
		var allocationSamples   = [];
		var operationsPerSample = arguments.iterations * arguments.operationsPerIteration;

		for ( var sampleIndex = 1; sampleIndex <= arguments.samples; sampleIndex++ ) {
			var allocationStart = variables.allocationSupported ? currentThreadAllocatedBytes() : 0;
			var cpuStart        = variables.cpuTimeSupported ? variables.threadBean.getCurrentThreadCpuTime() : 0;
			var wallStart       = variables.system.nanoTime();

			for ( var iterationIndex = 1; iterationIndex <= arguments.iterations; iterationIndex++ ) {
				consume( arguments.callback( iterationIndex ) );
			}

			var wallEnd       = variables.system.nanoTime();
			var cpuEnd        = variables.cpuTimeSupported ? variables.threadBean.getCurrentThreadCpuTime() : 0;
			var allocationEnd = variables.allocationSupported ? currentThreadAllocatedBytes() : 0;

			wallTimeSamples.append( ( wallEnd - wallStart ) / operationsPerSample );
			if ( variables.cpuTimeSupported ) {
				cpuTimeSamples.append( ( cpuEnd - cpuStart ) / operationsPerSample );
			}
			if ( variables.allocationSupported ) {
				allocationSamples.append( ( allocationEnd - allocationStart ) / operationsPerSample );
			}
		}

		var wallTime          = summarize( wallTimeSamples );
		wallTime.unit         = "nanoseconds_per_operation";
		wallTime.opsPerSecond = wallTime.median == 0 ? 0 : 1000000000 / wallTime.median;

		return {
			"name"                   : arguments.name,
			"category"               : arguments.category,
			"description"            : arguments.description,
			"warmupIterations"       : arguments.warmupIterations,
			"samples"                : arguments.samples,
			"iterationsPerSample"    : arguments.iterations,
			"operationsPerIteration" : arguments.operationsPerIteration,
			"operationsPerSample"    : operationsPerSample,
			"wallTime"               : wallTime,
			"cpuTime"                : {
				"supported" : variables.cpuTimeSupported,
				"unit"      : "nanoseconds_per_operation",
				"summary"   : variables.cpuTimeSupported ? summarize( cpuTimeSamples ) : {}
			},
			"allocation" : {
				"supported" : variables.allocationSupported,
				"unit"      : "bytes_per_operation",
				"summary"   : variables.allocationSupported ? summarize( allocationSamples ) : {}
			}
		};
	}

	/**
	 * Estimates retained heap per live item after full GC. The control trial keeps
	 * the same number of references to one shared object so most array overhead is
	 * removed from the result. Treat this as directional, not an object-size API.
	 */
	public struct function measureRetainedHeap(
		required string name,
		required any factory,
		numeric count      = 1000,
		numeric samples    = 3,
		string category    = "memory",
		string description = ""
	) {
		guardPositive( "count", arguments.count );
		guardPositive( "samples", arguments.samples );

		var warmupItems = [];
		for ( var warmupIndex = 1; warmupIndex <= min( arguments.count, 25 ); warmupIndex++ ) {
			warmupItems.append( arguments.factory( warmupIndex ) );
		}
		warmupItems = [];
		forceGc();

		var retainedSamples = [];
		var controlSamples  = [];
		var sharedSentinel  = createObject( "java", "java.lang.Object" ).init();

		for ( var sampleIndex = 1; sampleIndex <= arguments.samples; sampleIndex++ ) {
			forceGc();
			var controlStart = usedHeapBytes();
			var controlItems = [];
			for ( var controlIndex = 1; controlIndex <= arguments.count; controlIndex++ ) {
				controlItems.append( sharedSentinel );
			}
			variables.blackhole = controlItems;
			forceGc();
			var controlBytes = usedHeapBytes() - controlStart;
			controlSamples.append( controlBytes );
			controlItems        = [];
			variables.blackhole = 0;
			forceGc();

			var retainedStart = usedHeapBytes();
			var retainedItems = [];
			for ( var itemIndex = 1; itemIndex <= arguments.count; itemIndex++ ) {
				retainedItems.append( arguments.factory( itemIndex ) );
			}
			variables.blackhole = retainedItems;
			forceGc();
			var retainedBytes = usedHeapBytes() - retainedStart;
			retainedSamples.append( ( retainedBytes - controlBytes ) / arguments.count );
			retainedItems       = [];
			variables.blackhole = 0;
			forceGc();
		}

		return {
			"name"         : arguments.name,
			"category"     : arguments.category,
			"description"  : arguments.description,
			"count"        : arguments.count,
			"samples"      : arguments.samples,
			"unit"         : "approximate_retained_bytes_per_item",
			"summary"      : summarize( retainedSamples ),
			"controlBytes" : summarize( controlSamples ),
			"caveat"       : "Post-GC heap deltas are noisy and include engine bookkeeping. Use allocation results and profiler evidence for decisions."
		};
	}

	public struct function capabilities() {
		return {
			"threadCpuTime"        : variables.cpuTimeSupported,
			"threadAllocatedBytes" : variables.allocationSupported,
			"retainedHeapEstimate" : true
		};
	}

	private boolean function configureCpuTime() {
		try {
			if ( !variables.threadBean.isCurrentThreadCpuTimeSupported() ) {
				return false;
			}
			if ( !variables.threadBean.isThreadCpuTimeEnabled() ) {
				variables.threadBean.setThreadCpuTimeEnabled( true );
			}
			return variables.threadBean.isThreadCpuTimeEnabled();
		} catch ( any ignored ) {
			return false;
		}
	}

	private boolean function configureAllocationTracking() {
		try {
			if ( !variables.threadBean.isThreadAllocatedMemorySupported() ) {
				return false;
			}
			if ( !variables.threadBean.isThreadAllocatedMemoryEnabled() ) {
				variables.threadBean.setThreadAllocatedMemoryEnabled( true );
			}
			return variables.threadBean.isThreadAllocatedMemoryEnabled();
		} catch ( any ignored ) {
			return false;
		}
	}

	private numeric function currentThreadAllocatedBytes() {
		return variables.threadBean.getThreadAllocatedBytes( variables.threadId );
	}

	private void function consume( any value ) {
		if ( !isNull( arguments.value ) ) {
			variables.blackhole = arguments.value;
		}
	}

	private void function guardPositive( required string name, required numeric value ) {
		if ( arguments.value <= 0 ) {
			throw( type = "InvalidBenchmarkConfiguration", message = "#arguments.name# must be greater than zero." );
		}
	}

	private struct function summarize( required array values ) {
		if ( arguments.values.isEmpty() ) {
			return {};
		}

		var sorted = [];
		for ( var value in arguments.values ) {
			sorted.append( value );
		}
		arraySort( sorted, "numeric", "asc" );

		var total = 0;
		for ( var value in sorted ) {
			total += value;
		}
		var mean     = total / sorted.len();
		var variance = 0;
		for ( var value in sorted ) {
			variance += ( value - mean ) * ( value - mean );
		}
		variance /= sorted.len();

		return {
			"sampleCount"       : sorted.len(),
			"min"               : sorted[ 1 ],
			"median"            : percentile( sorted, 0.50 ),
			"mean"              : mean,
			"p95"               : percentile( sorted, 0.95 ),
			"max"               : sorted[ sorted.len() ],
			"standardDeviation" : sqr( variance ),
			"raw"               : sorted
		};
	}

	private numeric function percentile( required array sortedValues, required numeric percentile ) {
		var index = ceiling( arguments.sortedValues.len() * arguments.percentile );
		return arguments.sortedValues[ max( 1, min( arguments.sortedValues.len(), index ) ) ];
	}

	private numeric function usedHeapBytes() {
		return variables.runtime.totalMemory() - variables.runtime.freeMemory();
	}

	private void function forceGc() {
		variables.system.gc();
		sleep( 100 );
		variables.system.gc();
		sleep( 100 );
	}

}
