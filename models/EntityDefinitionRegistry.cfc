/**
 * Process-local registry for immutable entity definitions and their bounded
 * derived views. Definitions live for the module lifecycle and never compete
 * with request-shaped derived entries for eviction space.
 */
component singleton {

	public any function init( numeric defaultDerivedLimit = 16 ) {
		variables.defaultDerivedLimit        = max( 1, arguments.defaultDerivedLimit );
		variables.definitions                = newConcurrentMap();
		variables.derivedBuckets             = newConcurrentMap();
		variables.definitionLock             = newReentrantLock();
		variables.derivedLock                = newReentrantLock();
		variables.definitionCompilationCount = newAtomicLong();
		variables.derivedCompilationCount    = newAtomicLong();
		variables.derivedEvictionCount       = newAtomicLong();
		return this;
	}

	public any function getOrCreateDefinition( required string name, required any factory ) {
		var definition = variables.definitions.get( arguments.name );
		if ( !isNull( definition ) ) {
			return definition;
		}

		variables.definitionLock.lock();
		try {
			definition = variables.definitions.get( arguments.name );
			if ( isNull( definition ) ) {
				definition = arguments.factory();
				if ( isNull( definition ) ) {
					throw(
						type    = "QuickEntityDefinitionMissing",
						message = "The entity definition factory for [#arguments.name#] returned null."
					);
				}
				variables.definitions.put( arguments.name, definition );
				variables.definitionCompilationCount.incrementAndGet();
			}
		} finally {
			variables.definitionLock.unlock();
		}
		return definition;
	}

	public any function getDefinition( required string name ) {
		return variables.definitions.get( arguments.name );
	}

	public boolean function hasDefinition( required string name ) {
		return variables.definitions.containsKey( arguments.name );
	}

	public boolean function clearDefinition( required string name ) {
		var removed = variables.definitions.remove( arguments.name );
		clearDerived( arguments.name );
		return !isNull( removed );
	}

	public any function getOrCreateDerived(
		required string mapping,
		required string group,
		required string variant,
		required any factory,
		numeric limit = variables.defaultDerivedLimit
	) {
		arguments.limit = max( 1, arguments.limit );
		var bucketKey   = derivedBucketKey( arguments.mapping, arguments.group );
		var bucket      = variables.derivedBuckets.get( bucketKey );
		if ( !isNull( bucket ) && bucket.values.containsKey( arguments.variant ) ) {
			return bucket.values.get( arguments.variant );
		}

		variables.derivedLock.lock();
		try {
			bucket = getOrCreateDerivedBucket( bucketKey );
			if ( !bucket.values.containsKey( arguments.variant ) ) {
				var derived = arguments.factory();
				if ( isNull( derived ) ) {
					throw(
						type    = "QuickDerivedDefinitionMissing",
						message = "The derived definition factory for [#arguments.mapping#:#arguments.group#:#arguments.variant#] returned null."
					);
				}
				bucket.values.put( arguments.variant, derived );
				bucket.order.add( arguments.variant );
				variables.derivedCompilationCount.incrementAndGet();
				enforceDerivedLimit( bucket, arguments.limit );
			}
		} finally {
			variables.derivedLock.unlock();
		}
		return bucket.values.get( arguments.variant );
	}

	public any function getDerived(
		required string mapping,
		required string group,
		required string variant
	) {
		var bucket = variables.derivedBuckets.get( derivedBucketKey( arguments.mapping, arguments.group ) );
		if ( isNull( bucket ) ) {
			return javacast( "null", "" );
		}
		return bucket.values.get( arguments.variant );
	}

	public void function clearDerived( string mapping ) {
		if ( isNull( arguments.mapping ) ) {
			variables.derivedBuckets.clear();
			return;
		}
		var prefix   = arguments.mapping & chr( 31 );
		var iterator = variables.derivedBuckets.keySet().iterator();
		var keys     = [];
		while ( iterator.hasNext() ) {
			var key = iterator.next();
			if ( left( key, len( prefix ) ) == prefix ) {
				keys.append( key );
			}
		}
		for ( var key in keys ) {
			variables.derivedBuckets.remove( key );
		}
	}

	public void function clear() {
		variables.definitions.clear();
		variables.derivedBuckets.clear();
		variables.definitionCompilationCount.set( 0 );
		variables.derivedCompilationCount.set( 0 );
		variables.derivedEvictionCount.set( 0 );
	}

	public struct function getStats() {
		var derivedEntryCount = 0;
		var iterator          = variables.derivedBuckets.values().iterator();
		while ( iterator.hasNext() ) {
			derivedEntryCount += iterator.next().values.size();
		}
		return {
			"definitionCount"            : variables.definitions.size(),
			"definitionCompilationCount" : variables.definitionCompilationCount.get(),
			"derivedBucketCount"         : variables.derivedBuckets.size(),
			"derivedEntryCount"          : derivedEntryCount,
			"derivedCompilationCount"    : variables.derivedCompilationCount.get(),
			"derivedEvictionCount"       : variables.derivedEvictionCount.get()
		};
	}

	private any function getOrCreateDerivedBucket( required string bucketKey ) {
		var bucket = variables.derivedBuckets.get( arguments.bucketKey );
		if ( !isNull( bucket ) ) {
			return bucket;
		}
		var candidate = {
			"values" : newConcurrentMap(),
			"order"  : createObject( "java", "java.util.concurrent.ConcurrentLinkedQueue" ).init()
		};
		var existing = variables.derivedBuckets.putIfAbsent( arguments.bucketKey, candidate );
		return isNull( existing ) ? candidate : existing;
	}

	private void function enforceDerivedLimit( required struct bucket, required numeric limit ) {
		while ( arguments.bucket.values.size() > arguments.limit ) {
			var evictedKey = arguments.bucket.order.poll();
			if ( isNull( evictedKey ) ) {
				return;
			}
			if ( !isNull( arguments.bucket.values.remove( evictedKey ) ) ) {
				variables.derivedEvictionCount.incrementAndGet();
			}
		}
	}

	private string function derivedBucketKey( required string mapping, required string group ) {
		return arguments.mapping & chr( 31 ) & arguments.group;
	}

	private any function newConcurrentMap() {
		return createObject( "java", "java.util.concurrent.ConcurrentHashMap" ).init();
	}

	private any function newAtomicLong() {
		return createObject( "java", "java.util.concurrent.atomic.AtomicLong" ).init( 0 );
	}

	private any function newReentrantLock() {
		return createObject( "java", "java.util.concurrent.locks.ReentrantLock" ).init();
	}

}
