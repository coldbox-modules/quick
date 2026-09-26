component extends="coldbox.system.EventHandler" {

	property name="registry" inject="EntityDefinitionRegistry@quick";

	private any function entity( required string name ) {
		return getInstance( "quickService:" & arguments.name );
	}

	private void function json( event, data, numeric status = 200 ) {
		arguments.event.renderData(
			type       = "json",
			data       = arguments.data,
			statusCode = arguments.status
		);
	}

	private struct function payload( event ) {
		var data = deserializeJSON( toString( getHTTPRequestData().content ) );
		if (
			!isStruct( data ) || !structKeyExists( data, "title" ) || !len( trim( data.title ) ) || len( data.title ) > 80
		) {
			throw(
				type    = "SoakValidationFailed",
				message = "Invalid title",
				detail  = "title"
			);
		}
		if ( !structKeyExists( data, "ownerToken" ) || !reFind( "^[a-zA-Z0-9_-]{16,100}$", data.ownerToken ) ) {
			throw(
				type    = "SoakValidationFailed",
				message = "Invalid token",
				detail  = "ownerToken"
			);
		}
		return data;
	}

	function ready( event, rc, prc ) {
		var fixture = queryExecute(
			"SELECT version FROM fixture_manifest",
			{},
			{ "datasource" : "quick_soak" }
		);
		if ( fixture.recordCount != 1 || fixture.version[ 1 ] != "v1" ) {
			throw( type = "SoakFixtureMissing", message = "Fixture not ready" );
		}
		json(
			event,
			{
				"ready"          : true,
				"fixtureVersion" : fixture.version[ 1 ],
				"bootId"         : application.soakBootId
			}
		);
	}

	function diagnostics( event, rc, prc ) {
		var engine = getSystemMetrics();
		var errors = {};
		for ( var label in application.soakErrors ) {
			errors[ label ] = application.soakErrors[ label ].get();
		}
		var executorStats = {};
		if ( application.soakParallel ) {
			var executor  = getInstance( "AsyncManager@coldbox" ).getExecutor( "quick-parallel-eager-loading" );
			executorStats = {
				"maxThreads"    : executor.getMaximumPoolSize(),
				"poolSize"      : executor.getPoolSize(),
				"active"        : executor.getActiveCount(),
				"queued"        : executor.getQueue().size(),
				"queueCapacity" : application.soakExecutorCapacity,
				"completed"     : executor.getCompletedTaskCount()
			};
		}
		var runtime = createObject( "java", "java.lang.management.ManagementFactory" ).getRuntimeMXBean();
		var scratch = queryExecute(
			"SELECT COUNT(*) AS n FROM posts WHERE owner_token IS NOT NULL",
			{},
			{ "datasource" : "quick_soak" }
		);
		json(
			event,
			{
				"appName"              : getSetting( "appName" ),
				"parallelEagerLoading" : application.soakParallel,
				"executor"             : executorStats,
				"luceeVersion"         : server.lucee.version,
				"coldboxVersion"       : controller.getColdBoxVersion(),
				"exceptionHandler"     : getSetting( "exceptionHandler" ),
				"bootId"               : application.soakBootId,
				"applicationStarts"    : application.soakStartCount,
				"uptimeMs"             : runtime.getUptime(),
				"pid"                  : runtime.getPid(),
				"scratchPosts"         : scratch.n[ 1 ],
				"registry"             : registry.getStats(),
				"errors"               : errors,
				"jdbcActive"           : engine.activeDatasourceConnections,
				"jdbcIdle"             : engine.idleDatasourceConnections,
				"jdbcWaiting"          : engine.waitingForConn,
				"activeRequests"       : engine.activeRequests,
				"queuedRequests"       : engine.queueRequests,
				"applicationContexts"  : engine.applicationContextCount
			}
		);
	}

	function users( event, rc, prc ) {
		param rc.team       = 1;
		param rc.limit      = 25;
		param rc.page       = 1;
		param rc.nullable   = false;
		param rc.descending = false;
		var limit           = val( rc.limit ) == 100 ? 100 : 25;
		var page            = max( 1, min( 2, val( rc.page ) ) );
		var query           = entity( "User" ).newQuery();
		if ( val( rc.team ) > 0 ) {
			query.where( "teamId", val( rc.team ) );
		}
		if ( rc.nullable ) {
			query.whereNull( "nickname" );
		}
		var users = query
			.orderBy( "id", rc.descending ? "desc" : "asc" )
			.offset( ( page - 1 ) * limit )
			.limit( limit )
			.get();
		json(
			event,
			{
				"data" : users.map( function( user ) {
					return user.getMemento();
				} ),
				"page"  : page,
				"limit" : limit
			}
		);
	}

	function user( event, rc, prc ) {
		prc.soakCase    = "missing_pk";
		var user        = entity( "User" ).with( "team" ).findOrFail( rc.id );
		var data        = user.getMemento( includes = "team" );
		data[ "posts" ] = user
			.posts()
			.where( "id", "<=", 10000 )
			.orderBy( "id", "desc" )
			.limit( 5 )
			.get()
			.map( function( post ) {
				return post.getMemento();
			} );
		json( event, { "data" : data } );
	}

	function lookup( event, rc, prc ) {
		prc.soakCase     = "empty_lookup";
		param rc.email   = "missing@example.invalid";
		var query        = entity( "User" ).where( "email", rc.email );
		param rc.message = "default";
		if ( rc.message == "custom" ) {
			var user = query.firstOrFail( "Soak lookup missing" );
		} else if ( rc.message == "callback" ) {
			var user = query.firstOrFail( function( missing ) {
				return "Soak callback missing";
			} );
		} else {
			var user = query.firstOrFail();
		}
		json( event, { "data" : user.getMemento() } );
	}

	function relatedPost( event, rc, prc ) {
		prc.soakCase = "relationship";
		var user     = entity( "User" ).findOrFail( rc.id );
		var post     = user
			.posts()
			.where( "id", rc.postId )
			.firstOrFail();
		json( event, { "data" : post.getMemento() } );
	}

	function posts( event, rc, prc ) {
		param rc.start = 1;
		var start      = max( 1, min( 9996, val( rc.start ) ) );
		var posts      = entity( "Post" )
			.whereBetween( "id", start, start + 4 )
			.with( [ "author", "comments.author", "tags" ], application.soakParallel )
			.orderBy( "id" )
			.get();
		json(
			event,
			{
				"data" : posts.map( function( post ) {
					return post.getMemento( includes = "author,comments,comments.author,tags" );
				} )
			}
		);
	}

	function report( event, rc, prc ) {
		param rc.limit = 100;
		var limit      = listFind( "25,50,100,250,500,1000", rc.limit ) ? val( rc.limit ) : 100;
		if ( limit == 100 && application.soakFaultStarted > 0 ) {
			var elapsed = getTickCount() - application.soakFaultStarted;
			if (
				listFind( "latency,late-latency", application.soakFaultMode ) &&
				elapsed > application.soakFaultDelayMs
			) {
				sleep( 750 );
			}
		}
		var data = entity( "Post" )
			.where( "id", "<=", limit )
			.orderBy( "id" )
			.get()
			.map( function( post ) {
				return post.getMemento(
					includes = "id,userId,title,summary",
					excludes = "createdAt,updatedAt,ownerToken,profile,lifecycleCount"
				);
			} );
		// Canonical checksum is independent of JSON property ordering and engine formatting.
		var canonical = data
			.map( function( post ) {
				return "#post.id#:#post.userId#:#post.title#";
			} )
			.toList( "|" );
		json(
			event,
			{
				"data"     : data,
				"checksum" : lCase( hash( canonical, "SHA-256" ) )
			}
		);
	}

	function variant( event, rc, prc ) {
		var variant = val( rc.variant );
		if ( variant < 0 || variant > 31 || variant != int( variant ) ) {
			throw( type = "SoakInvalidVariant", message = "Variant is outside the allowlist" );
		}
		// 32 actual table aliases exceed the qualifiedColumns derived-cache limit (16).
		var user = entity( "User" ).withAlias( "shape_" & variant );
		user.retrieveQualifiedColumns();
		var selected = variant MOD 2 == 0 ? "id,displayName,nickname" : "id,displayName,nickname,teamId";
		user         = user
			.select( listToArray( selected ) )
			.where( "id", 1 + variant )
			.firstOrFail();
		json(
			event,
			{
				"variant" : variant,
				"data"    : user.getMemento( includes = selected, ignoreDefaults = true )
			}
		);
	}

	function createPost( event, rc, prc ) {
		prc.soakCase = "invalid_write";
		var body     = payload( event );
		transaction {
			var post = entity( "Post" ).create( {
				"userId"     : 1,
				"title"      : body.title,
				"summary"    : javacast( "null", "" ),
				"ownerToken" : body.ownerToken,
				"profile"    : { "level" : 7 }
			} );
			post.tags().attach( [ 1, 2 ] );
		}
		json(
			event,
			{ "data" : post.getMemento() },
			201
		);
	}

	private any function ownedPost( rc ) {
		param arguments.rc.token = "";
		return entity( "Post" )
			.where( "ownerToken", arguments.rc.token )
			.where( "id", arguments.rc.id )
			.firstOrFail();
	}

	function post( event, rc, prc ) {
		prc.soakCase = "post_delete";
		var post     = ownedPost( rc );
		json( event, { "data" : post.getMemento( includes = "tags" ) } );
	}

	function updatePost( event, rc, prc ) {
		var body = payload( event );
		if ( body.ownerToken != ( rc.token ?: "" ) ) {
			throw( type = "SoakValidationFailed", message = "Invalid token" );
		}
		var post = ownedPost( rc );
		post.update( { "title" : body.title } );
		json( event, { "data" : post.getMemento() } );
	}

	function deletePost( event, rc, prc ) {
		transaction {
			var post = ownedPost( rc );
			post.tags().detach( [ 1, 2 ] );
			post.delete();
		}
		json( event, { "deleted" : true } );
	}

	function rollback( event, rc, prc ) {
		prc.soakCase = "rollback";
		var body     = payload( event );
		transaction {
			var post = entity( "Post" ).create( {
				"userId"     : 1,
				"title"      : body.title,
				"ownerToken" : body.ownerToken,
				"profile"    : { "level" : 7 }
			} );
			post.tags().attach( [ 1, 2 ] );
			entity( "User" ).findOrFail( 2000000000, function( missing, id ) {
				return "Soak rollback missing";
			} );
		}
		// This can only run if Quick incorrectly fails to throw. k6 must reject it.
		json(
			event,
			{ "unexpectedSuccess" : true },
			200
		);
	}

	function scratch( event, rc, prc ) {
		var count   = entity( "Post" ).where( "ownerToken", rc.token ).count();
		var orphans = queryExecute(
			"SELECT COUNT(*) AS n FROM post_tags pt LEFT JOIN posts p ON pt.post_id=p.id WHERE p.id IS NULL",
			{},
			{ "datasource" : "quick_soak" }
		);
		json(
			event,
			{
				"posts"        : count,
				"orphanPivots" : orphans.n[ 1 ]
			}
		);
	}

	function onException( event, rc, prc ) {
		var exception = prc.exception.getExceptionStruct();
		var type      = exception.type ?: "Unknown";
		var label     = prc.soakCase ?: "unexpected";
		if ( type != "EntityNotFound" && type != "SoakValidationFailed" ) {
			label = "unexpected";
		}
		if ( !structKeyExists( application.soakErrors, label ) ) {
			label = "unexpected";
		}
		application.soakErrors[ label ].incrementAndGet();
		if ( type == "EntityNotFound" ) {
			json(
				event,
				{
					"error" : {
						"code" : application.soakFaultMode == "wrong-contract" && application.soakFaultStarted > 0 ? "WrongErrorCode" : "EntityNotFound",
						"type" : "EntityNotFound"
					}
				},
				404
			);
		} else if ( type == "SoakValidationFailed" ) {
			var fields      = {};
			var field       = exception.detail == "title" ? "title" : "ownerToken";
			fields[ field ] = field == "title" ? "required,maximum:80" : "required,format";
			json(
				event,
				{
					"error" : {
						"code"   : "ValidationFailed",
						"fields" : fields
					}
				},
				422
			);
		} else {
			log.error(
				"Unexpected harness exception",
				{
					"type"    : type,
					"message" : left( exception.message ?: "", 512 ),
					"detail"  : left( exception.detail ?: "", 512 )
				}
			);
			json(
				event,
				{
					"error" : {
						"code" : "UnexpectedError",
						"type" : type
					}
				},
				500
			);
		}
	}

}
