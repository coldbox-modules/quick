/**
 *  QueryBuilder super-type to add additional Quick-only features like relationship querying and ordering to qb queries.
 */
component accessors="true" transientCache="false" {

	/**
	 * The entity associated with this builder.
	 */
	property name="entity";

	/**
	 * The QueryBuilder instance associated with this QuickBuilder
	 */
	property name="qb" inject="QuickQB@quick";

	/**
	 * A boolean flag representing that the entity is currently applying global scopes.
	 */
	property name="_applyingGlobalScopes" default="false";

	/**
	 * A boolean flag representing that the entity has already applied global scopes.
	 */
	property name="_globalScopesApplied" default="false";

	/**
	 * A boolean flag representing if global scopes should not be activated or not.
	 */
	property name="_globalScopeExcludeAll" default="false";

	/**
	 * An array of global scopes to exclude from being applied. Added using the `withoutGlobalScope` method.
	 */
	property name="_globalScopeExclusions";

	/**
	 * An array of relationships to eager load.
	 */
	property name="_eagerLoad";

	/**
	 * A flag marking if this builder should return as a qb result or as a collection of entities.
	 */
	property name="_asQuery";

	/**
	 * A flag marking if this builder should use aliases instead of column names.  Only applies with `_asQuery` being true.
	 */
	property name="_withAliases";

	/**
	 * A map of aliases to entities to use when qualifying aliased columns.
	 */
	property name="aliasMap";

	/**
	 * The WireBox injector.  Used to inject other entities.
	 */
	property name="_wirebox" inject="wirebox";

	property name="_asMemento" default="false";
	property name="_asMementoSettings";

	/**
	 * Used to quickly identify QueryBuilder instances
	 * instead of resorting to `isInstanceOf` which is slow.
	 */
	this.isBuilder = true;

	/**
	 * Used to quickly identify QuickBuilder instances
	 * instead of resorting to `isInstanceOf` which is slow.
	 */
	this.isQuickBuilder = true;

	function init() {
		variables._eagerLoad             = [];
		variables._globalScopesApplied   = false;
		variables._globalScopeExcludeAll = false;
		variables._asMemento             = false;
		variables._asQuery               = false;
		variables._withAliases           = false;
		variables._asMementoSettings     = {};
		variables._globalScopeExclusions = [];
		variables.aliasMap               = {};
		return this;
	}

	function onDIComplete() {
		variables.qb.setQuickBuilder( this );
		variables.qb.setColumnFormatter( function( column ) {
			return qualifyColumn( column );
		} );
	}

	public QuickBuilder function setEntity( required any newEntity ) {
		variables.entity = arguments.newEntity;
		variables.qb.setEntity( arguments.newEntity );
		variables.aliasMap[ arguments.newEntity.tableAlias() ] = arguments.newEntity;
		return this;
	}

	/**
	 * Sets an alias for the current table name.
	 *
	 * @alias   The alias to use.
	 *
	 * @return  quick.models.BaseEntity
	 */
	public QuickBuilder function withAlias( required string alias ) {
		variables.aliasMap.delete( getEntity().tableAlias() );
		getEntity().withAlias( arguments.alias );
		variables.qb.withAlias( arguments.alias );
		return this;
	}

	/**
	 * Adds a subselect query with the given name to the entity.
	 * Useful for computed properties and computed relationship keys.
	 *
	 * @name       The name to use for the subselect result on the entity.
	 * @subselect  The subselect query builder instance or closure to configure
	 *             the subselect.
	 *
	 * @return     quick.models.BaseEntity
	 */
	public any function addSubselect( required string name, required any subselect ) {
		getEntity().appendVirtualAttribute( arguments.name );

		if (
			variables.qb.getColumns().isEmpty() ||
			(
				variables.qb.getColumns().len() == 1 &&
				isSimpleValue( variables.qb.getColumns()[ 1 ] ) &&
				variables.qb.getColumns()[ 1 ] == "*"
			)
		) {
			variables.qb.select( variables.qb.getFrom() & ".*" );
		}

		var subselectQuery = arguments.subselect;
		if ( isClosure( subselectQuery ) || isCustomFunction( subselectQuery ) ) {
			subselectQuery = variables.qb.newQuery();
			arguments.subselect( subselectQuery );
		} else if ( isSimpleValue( subselectQuery ) && listLen( subselectQuery, "." ) > 1 ) {
			var column = subselectQuery;
			var q      = javacast( "null", "" );
			while ( listLen( column, "." ) > 1 ) {
				var relationshipName = listFirst( column, "." );
				if ( isNull( q ) ) {
					q = getEntity().ignoreLoadedGuard( function() {
						return getEntity().withoutRelationshipConstraints( relationshipName, function() {
							return invoke( getEntity(), relationshipName ).addCompareConstraints();
						} );
					} );
				} else {
					var relationship = q
						.getEntity()
						.ignoreLoadedGuard( function() {
							return q
								.getEntity()
								.withoutRelationshipConstraints( relationshipName, function() {
									return invoke( q.getEntity(), relationshipName );
								} );
						} );
					q.select( q.raw( 1 ) );
					if ( structKeyExists( qb, "isQuickBuilder" ) ) {
						q.getQB();
					}
					var relationshipQuery = relationship.addCompareConstraints( q );
					if ( structKeyExists( relationshipQuery, "getRelationshipBuilder" ) ) {
						relationshipQuery = relationshipQuery.getRelationshipBuilder();
					}
					if ( structKeyExists( relationshipQuery, "isQuickBuilder" ) ) {
						relationshipQuery = relationshipQuery.getQB();
					}
					q = relationship.whereExists( relationshipQuery );
				}
				column = listRest( column, "." );
			}
			subselectQuery = q.select( q.qualifyColumn( column ) );
		}

		subselectQuery.limit( 1 )

		if ( structKeyExists( subselectQuery, "getRelationshipBuilder" ) ) {
			subselectQuery = subselectQuery.getRelationshipBuilder();
		}

		if ( structKeyExists( subselectQuery, "isQuickBuilder" ) ) {
			subselectQuery = subselectQuery.getQB();
		}

		variables.qb.subselect( name, subselectQuery );
		return this;
	}

	/**
	 * Adds a JOIN to another table.
	 *
	 * For simple joins, this specifies a column on which to join the two tables.
	 * For complex joins, a closure can be passed to `first`.
	 * This allows multiple `on` and `where` conditions to be applied to the join.
	 *
	 * @table The table/expression to join to the query.
	 * @first The first column in the join's `on` statement. This alternatively can be a closure that will be passed a JoinClause for complex joins. Passing a closure ignores all subsequent parameters.
	 * @operator The boolean operator for the join clause. Default: "=".
	 * @second The second column in the join's `on` statement.
	 * @type The type of the join. Default: "inner".  Passing this as an argument is discouraged for readability.  Use the dedicated methods like `leftJoin` and `rightJoin` where possible.
	 * @where Sets if the value of `second` should be interpreted as a column or a value.  Passing this as an argument is discouraged.  Use the dedicated `joinWhere` or a join closure where possible.
	 * @preventDuplicateJoins Introspects the builder for a join matching the join we're trying to add. If a match is found, disregards this request. Defaults to moduleSetting or qb setting
	 *
	 * @return qb.models.Query.QueryBuilder
	 */
	public QuickBuilder function join(
		required any table,
		any first,
		string operator = "=",
		string second,
		string type                   = "inner",
		boolean where                 = false,
		boolean preventDuplicateJoins = this.getPreventDuplicateJoins()
	) {
		variables.qb                                         = variables.qb.join( argumentCollection = arguments );
		var latestJoin                                       = variables.qb.getJoins().last();
		var latestJoinBuilder                                = latestJoin.getParentQuery().getQuickBuilder();
		variables.aliasMap[ latestJoinBuilder.tableAlias() ] = latestJoinBuilder.getEntity();
		return this;
	}

	/**
	 * Adds a count of related entities as a subselect property.
	 * Relationships can be constrained at runtime by passing a
	 * struct where the key is the relationship name and the value
	 * is a function to constrain the query.
	 *
	 * @relation  A single relation name or array of relation names to load counts.
	 *
	 * @return    quick.models.BaseEntity
	 */
	public any function withCount( required any relation, boolean asBuilder = false ) {
		var builders = [];
		for ( var r in arrayWrap( arguments.relation ) ) {
			var relationName = r;
			var callback     = function() {
			};

			if ( isStruct( r ) ) {
				for ( var key in r ) {
					relationName = key;
					callback     = r[ key ];
					break;
				}
			}

			var subselectName = getEntity().get_str().camel( relationName & " Count" );
			if ( findNoCase( " as ", relationName ) ) {
				var parts     = relationName.split( "\s(?:A|a)(?:S|s)\s" );
				relationName  = parts[ 1 ];
				subselectName = parts[ 2 ];
			}

			var countBuilder = getEntity().ignoreLoadedGuard( function() {
				return getEntity().withoutRelationshipConstraints( relationName, function() {
					return invoke( getEntity(), relationName )
						.addCompareConstraints()
						.when( true, callback )
						.clearOrders()
						.reselectRaw( "COUNT(*)" );
				} );
			} );

			if ( arguments.asBuilder ) {
				builders.append( countBuilder );
			} else {
				addSubselect( subselectName, countBuilder );
			}
		}

		return arguments.asBuilder ? builders : this;
	}

	/**
	 * Adds a sum of a related entity attribute as a subselect attribute.
	 * Relationships can be constrained at runtime by passing a
	 * struct where the key is the relationship name and the value
	 * is a function to constrain the query.
	 *
	 * @relation  A single relation name or array of relation names to load counts.
	 *
	 * @return    quick.models.BaseEntity
	 */
	public any function withSum( required any relationMapping, boolean asBuilder = false ) {
		var builders = [];
		for ( var r in arrayWrap( arguments.relationMapping ) ) {
			var relationName = r;
			var callback     = function() {
			};

			if ( isStruct( relationName ) ) {
				for ( var key in relationName ) {
					callback     = relationName[ key ];
					relationName = key;
					break;
				}
			}

			if ( listLen( relationName, "." ) > 2 ) {
				throw(
					type    = "QuickInvalidRelationshipSumMapping",
					message = "`withSum` only supports a single relationship level.  Your string should match the pattern `relationName.attributeName`."
				);
			}
			var attributeName = listLast( relationName, "." );
			relationName      = listFirst( relationName, "." );

			var subselectName = getEntity().get_str().camel( "Total " & relationName );
			if ( findNoCase( " as ", attributeName ) ) {
				var parts     = attributeName.split( "\s(?:A|a)(?:S|s)\s" );
				attributeName = parts[ 1 ];
				subselectName = parts[ 2 ];
			}

			var sumBuilder = getEntity().ignoreLoadedGuard( function() {
				return getEntity().withoutRelationshipConstraints( relationName, function() {
					var related = invoke( getEntity(), relationName );
					return related
						.addCompareConstraints()
						.when( true, callback )
						.clearOrders()
						.reselectRaw( "COALESCE(SUM(#related.qualifyColumn( attributeName )#), 0)" );
				} );
			} );

			if ( arguments.asBuilder ) {
				builders.append( sumBuilder );
			} else {
				addSubselect( subselectName, sumBuilder );
			}
		}

		return arguments.asBuilder ? builders : this;
	}

	/**
	 * Executes the configured query and returns the entities in an array.
	 *
	 * @doc_generic  quick.models.BaseEntity
	 * @return       [quick.models.BaseEntity]
	 */
	private array function getEntities() {
		var results = variables.qb.get();
		return variables._asQuery ? results : results.map( variables.loadEntity );
	}

	/**
	 * Retrieves all the entities.
	 * It does this by resetting the configured query before retrieving the results.
	 *
	 * @return  The result of `newCollection` with the retrieved entities.
	 */
	public any function all() {
		return variables.get();
	}

	/**
	 * Runs the current select query.
	 *
	 * @columns  An optional column, list of columns, or array of columns to select.
	 *           The selected columns before calling get will be restored after running the query.
	 * @options  Any options to pass to `queryExecute`. Default: {}.
	 *
	 * @return   any
	 */
	public any function get( any columns, struct options = {} ) {
		activateGlobalScopes();
		return getEntity().newCollection( handleTransformations( eagerLoadRelations( getEntities() ) ) );
	}

	/**
	 * Updates matching entities with the given attributes according to the configured query.
	 *
	 * @attributes  The attributes to update on the matching records.
	 * @force       If true, skips read-only entity and read-only attribute checks.
	 *
	 * @throws      QuickReadOnlyException
	 *
	 * @return      { "query": QueryBuilder Return Format, "result": struct }
	 */
	public struct function updateAll( struct attributes = {}, boolean force = false ) {
		if ( !arguments.force ) {
			getEntity().guardReadOnly();
			getEntity().guardAgainstReadOnlyAttributes( arguments.attributes );
		}
		return variables.qb.update(
			arguments.attributes.map( function( key, value ) {
				return getEntity().generateQueryParamStruct(
					column = key,
					value  = isNull( value ) ? javacast( "null", "" ) : value
				);
			} )
		);
	}

	/**
	 * When is a useful helper method that introduces if / else control flow without breaking chainability.
	 * When the `condition` is true, the `onTrue` callback is triggered.  If the `condition` is false and an `onFalse` callback is passed, it is triggered.  Otherwise, the query is returned unmodified.
	 *
	 * @condition       A boolean condition that if true will trigger the `onTrue` callback. If not true, the `onFalse` callback will trigger if it was passed. Otherwise, the query is returned unmodified.
	 * @onTrue          A closure that will be triggered if the `condition` is true.
	 * @onFalse         A closure that will be triggered if the `condition` is false.
	 * @withoutScoping  Flag to turn off the automatic scoping of where clauses during the callback.
	 *
	 * @return          qb.models.Query.QueryBuilder
	 */
	public QuickBuilder function when(
		required boolean condition,
		required function onTrue,
		function onFalse,
		boolean withoutScoping = false
	) {
		var defaultCallback = function( q ) {
			return q;
		};
		arguments.onFalse = isNull( arguments.onFalse ) ? defaultCallback : arguments.onFalse;

		if ( arguments.withoutScoping ) {
			if ( arguments.condition ) {
				arguments.onTrue( this );
			} else {
				arguments.onFalse( this );
			}
		} else {
			variables.qb.withScoping( function() {
				if ( condition ) {
					onTrue( this );
				} else {
					onFalse( this );
				}
			} );
		}

		return this;
	}

	/**
	 * Deletes matching entities according to the configured query.
	 *
	 * @ids     An optional array of ids to add to the previously configured
	 *          query.  The ids will be added to a WHERE IN statement on the
	 *          primary key column.
	 *
	 * @throws  QuickReadOnlyException
	 *
	 * @return  { "query": QueryBuilder Return Format, "result": struct }
	 */
	public struct function deleteAll( array ids = [] ) {
		getEntity().guardReadOnly();
		if ( !arrayIsEmpty( arguments.ids ) ) {
			variables.qb.where( function( q1 ) {
				ids.each( function( id ) {
					var values = arrayWrap( id );
					getEntity().guardAgainstKeyLengthMismatch( values );
					q1.orWhere( function( q2 ) {
						getEntity()
							.keyNames()
							.each( function( keyName, i ) {
								q2.where( keyName, values[ i ] );
							} );
					} );
				} );
			} );
		}
		return variables.qb.delete();
	}

	/**
	 * Add an relation or an array of relations to be eager loaded.
	 * Eager loaded relations are retrieved at the same time as loading
	 * the original query decreasing the number of queries that need
	 * to be ran for the same data.
	 *
	 * @relationName  A single relation name or array of relation
	 *                names to eager load.
	 *
	 * @return        QuickBuilder
	 */
	public any function with( required any relationName ) {
		if ( isSimpleValue( arguments.relationName ) && arguments.relationName == "" ) {
			return this;
		}

		arrayAppend(
			variables._eagerLoad,
			arrayWrap( arguments.relationName ),
			true
		);

		return this;
	}

	/**
	 * Eager loads the configured relations for the retrieved entities.
	 * Returns the retrieved entities eager loaded with the configured
	 * relationships.
	 *
	 * @entities     The retrieved entities or array of structs to eager load.
	 *
	 * @doc_generic  quick.models.BaseEntity | struct
	 * @return       [quick.models.BaseEntity] | [struct]
	 */
	private array function eagerLoadRelations( required array entities ) {
		if ( arguments.entities.isEmpty() || variables._eagerLoad.isEmpty() ) {
			return arguments.entities;
		}

		// This is a workaround for grammars with a parameter limit.  If the grammar
		// has a `parameterLimit` public property, it is used to slice up the array
		// and work it in chunks.
		if ( structKeyExists( getEntity().newQuery().getGrammar(), "parameterLimit" ) ) {
			var parameterLimit = getEntity().newQuery().getGrammar().parameterLimit;
			if ( arguments.entities.len() > parameterLimit ) {
				for ( var i = 1; i < arguments.entities.len(); i += parameterLimit ) {
					var length = min( arguments.entities.len() - i + 1, parameterLimit );
					var slice  = arraySlice( arguments.entities, i, length );
					eagerLoadRelations( slice );
				}
				return arguments.entities;
			}
		}

		arrayEach( variables._eagerLoad, function( relationName ) {
			entities = eagerLoadRelation( relationName, entities );
		} );

		return arguments.entities;
	}

	/**
	 * Eager loads the given relation for the retrieved entities.
	 * Returns the retrieved entities eager loaded with the given relation.
	 *
	 * @relationName  The relationship to eager load.
	 * @entities      The retrieved entities or array of structs to eager load the relationship.
	 *
	 * @doc_generic   quick.models.BaseEntity | struct
	 * @return        [quick.models.BaseEntity] | [struct]
	 */
	private array function eagerLoadRelation( required any relationName, required array entities ) {
		var callback = function() {
		};
		if ( !isSimpleValue( arguments.relationName ) ) {
			if ( !isStruct( arguments.relationName ) ) {
				throw(
					type    = "QuickInvalidEagerLoadParameter",
					message = "Only strings or structs are supported eager load parameters.  You passed [#serializeJSON( arguments.relationName )#"
				);
			}
			for ( var key in arguments.relationName ) {
				callback               = arguments.relationName[ key ];
				arguments.relationName = key;
				break;
			}
		}
		var currentRelationship = listFirst( arguments.relationName, "." );
		var relation            = getEntity().ignoreLoadedGuard( function() {
			return getEntity().withoutRelationshipConstraints( currentRelationship, function() {
				return invoke( getEntity(), currentRelationship );
			} );
		} );
		callback( relation );
		var hasMatches = relation.addEagerConstraints( arguments.entities, getEntity() );
		relation.with( listRest( arguments.relationName, "." ) );
		return relation.match(
			relation.initRelation( arguments.entities, currentRelationship ),
			hasMatches ? relation.getEager( variables._asQuery, variables._withAliases ) : [],
			currentRelationship
		);
	}

	/**
	 * Orders the query by a field in a relationship.
	 * Uses subquery ordering to accomplish this.
	 *
	 * @relationshipName  The relationship name to order.  This can be a
	 *                    dot-delimited list of nested relationships or an array of relationship names.
	 * @columnName        The column name in the final relationship to order by.
	 * @direction         The direction to sort, `asc` or `desc`.
	 *
	 * @return            quick.models.QuickBuilder
	 */
	public QuickBuilder function orderByRelated(
		required any relationshipName,
		required string columnName,
		string direction = "asc"
	) {
		if ( isArray( arguments.relationshipName ) ) {
			arguments.relationshipName = arguments.relationshipName.toList( "." );
		}
		var q = javacast( "null", "" );
		while ( listLen( arguments.relationshipName, "." ) > 0 ) {
			var thisRelationshipName = listFirst( arguments.relationshipName, "." );
			if ( isNull( q ) ) {
				q = getEntity().ignoreLoadedGuard( function() {
					return getEntity().withoutRelationshipConstraints( thisRelationshipName, function() {
						return invoke( getEntity(), thisRelationshipName ).addCompareConstraints().clearOrders();
					} );
				} );
			} else {
				var relationship = q
					.getEntity()
					.ignoreLoadedGuard( function() {
						return q
							.getEntity()
							.withoutRelationshipConstraints( thisRelationshipName, function() {
								return invoke( q.getEntity(), thisRelationshipName );
							} );
					} );

				var existsQuery = relationship.addCompareConstraints( q.select( q.raw( 1 ) ) ).clearOrders();

				if ( structKeyExists( existsQuery, "isQuickBuilder" ) ) {
					existsQuery = existsQuery.getQB();
				}

				q = relationship.whereExists( existsQuery );
			}
			arguments.relationshipName = listRest( arguments.relationshipName, "." );
		}

		q.select( arguments.columnName );

		if ( structKeyExists( q, "relationshipClass" ) ) {
			q = q.retrieveQuery();
		}

		if ( structKeyExists( q, "isQuickBuilder" ) ) {
			q = q.getQB();
		}

		variables.qb.orderBy( q, arguments.direction );

		return this;
	}

	public QuickBuilder function addAliasesFromBuilder( required any otherBuilder ) {
		variables.aliasMap.append( otherBuilder.getAliasMap() );
		return this;
	}

	/**
	 * Qualifies a column with the entity's table name.
	 *
	 * @column  The column to qualify.
	 *
	 * @return  string
	 */
	public string function qualifyColumn( required string column, string tableName ) {
		if ( findNoCase( ".", column ) != 0 ) {
			var columnAlias = listFirst( column, "." );
			for ( var tableAlias in variables.aliasMap ) {
				if ( compareNoCase( columnAlias, tableAlias ) == 0 ) {
					return variables.aliasMap[ tableAlias ].qualifyColumn( listLast( column, "." ), columnAlias );
				}
			}
		}
		return getEntity().qualifyColumn( argumentCollection = arguments );
	}

	/**
	 * Returns the table name of the underlying entity
	 */
	public string function tableName() {
		return getEntity().tableName();
	}

	/**
	 * Returns the table alias of the underlying entity
	 */
	public string function tableAlias() {
		return getEntity().tableAlias();
	}

	/**
	 * Returns the mapping name of the underlying entity
	 */
	public string function mappingName() {
		return getEntity().mappingName();
	}

	/**
	 * Creates a new query using the same Grammar and QueryUtils.
	 *
	 * @return quick.models.QuickBuilder
	 */
	// public QuickBuilder function newQuery() {
	// 	var builder = new quick.models.QuickBuilder(
	// 		grammar               = getGrammar(),
	// 		utils                 = getUtils(),
	// 		returnFormat          = getReturnFormat(),
	// 		paginationCollector   = isNull( variables.paginationCollector ) ? javacast( "null", "" ) : variables.paginationCollector,
	// 		defaultOptions        = getDefaultOptions(),
	// 		preventDuplicateJoins = getPreventDuplicateJoins()
	// 	);
	// 	builder.setEntity( getEntity() );
	// 	builder.setFrom( getEntity().tableName() );
	// 	builder.setColumnFormatter( function( column ) {
	// 		return builder.qualifyColumn( column );
	// 	} );
	// 	applyInheritanceJoins( builder );
	// 	return builder;
	// }

	function applyInheritanceJoins() {
		var entity = getEntity();
		// Apply and append any inheritance joins/columns
		if ( entity.hasParentEntity() && !entity.isSingleTableInheritance() ) {
			var parentDefinition = entity.getParentDefinition();
			variables.qb.join(
				parentDefinition.meta.table,
				parentDefinition.meta.table & "." & parentDefinition.key,
				entity.qualifyColumn( entity.keyNames()[ 1 ] )
			);
		} else if ( entity.isDiscriminatedParent() && entity.get_loadChildren() ) {
			entity
				.getDiscriminations()
				.each( function( discriminator, data ) {
					// only join if this is a polymorphicn association
					if ( !entity.isSingleTableInheritance() ) {
						variables.qb.join(
							data.table,
							getEntity().qualifyColumn( getEntity().keyNames()[ 1 ] ),
							"=",
							data.joincolumn,
							"left outer"
						);
					}
					variables.qb.addSelect( data.childColumns );
				} );
		}
	}

	/**
	 * Creates a virtual attribute for the given name.
	 *
	 * @name    The attribute name to create.
	 *
	 * @return  quick.models.BaseEntity
	 */
	public any function appendVirtualAttribute( required string name, boolean excludeFromMemento = false ) {
		getEntity().appendVirtualAttribute( argumentCollection = arguments );
		return this;
	}

	/**
	 * Quick tries a lot of things when encountering a missing method.
	 * Here they are in order:
	 *
	 * 1. `scope{missingMethodName}` methods
	 * 2. Forwarding the method call to qb
	 *
	 * If none of those steps are successful, it throws a `QuickMissingMethod` exception.
	 *
	 * @missingMethodName       The method name that is missing.
	 * @missingMethodArguments  The arguments passed to the missing method call.
	 *
	 * @throws                  QuickMissingMethod
	 *
	 * @return                  any
	 */
	public any function onMissingMethod( required string missingMethodName, struct missingMethodArguments = {} ) {
		var result = getEntity().tryScopes(
			arguments.missingMethodName,
			arguments.missingMethodArguments,
			this,
			variables._applyingGlobalScopes ? variables._globalScopeExclusions : []
		);

		if ( !isNull( result ) ) {
			// If a query is returned, set it as the current query and return
			// the entity. Otherwise return whatever came back from the scope.
			if (
				isStruct( result ) &&
				structKeyExists( result, "isBuilder" ) &&
				!structKeyExists( result, "isQuickBuilder" )
			) {
				variables.qb = result;
				return this;
			}

			return result;
		}

		result = invoke(
			variables.qb,
			arguments.missingMethodName,
			arguments.missingMethodArguments
		);

		if ( !isNull( result ) ) {
			// If a query is returned, set it as the current query and return
			// the entity. Otherwise return whatever came back from the scope.
			if (
				isStruct( result ) &&
				structKeyExists( result, "isBuilder" ) &&
				!structKeyExists( result, "isQuickBuilder" )
			) {
				variables.qb = result;
				return this;
			}
			return result;
		}

		return javacast( "null", "" );
	}

	/**
	 * Returns the entity with the id value as the primary key.
	 * If no record is found, it returns null instead.
	 *
	 * @id      The id value to find.
	 *
	 * @return  quick.models.BaseEntity || null
	 */
	public any function find( required any id ) {
		arguments.id = arrayWrap( arguments.id );
		getEntity().guardAgainstKeyLengthMismatch( arguments.id );
		getEntity().fireEvent(
			"preLoad",
			{
				id       : arguments.id,
				metadata : getEntity().get_meta()
			}
		);
		activateGlobalScopes();
		return this
			.where( function( q ) {
				var allKeyNames = getEntity().keyNames();
				for ( var i = 1; i <= allKeyNames.len(); i++ ) {
					q.where( allKeyNames[ i ], id[ i ] );
				}
			} )
			.first();
	}

	/**
	 * Returns the first matching entity for the configured query.
	 * If no records are found, it throws an `EntityNotFound` exception.
	 *
	 * @errorMessage  An optional string error message or callback to produce
	 *                a string error message.  If a callback is used, it is
	 *                passed the unloaded entity as the only argument.
	 *
	 * @throws        EntityNotFound
	 *
	 * @return        quick.models.BaseEntity
	 */
	public any function firstOrFail( any errorMessage ) {
		activateGlobalScopes();
		var instance = this.first();
		if ( isNull( instance ) ) {
			param arguments.errorMessage = "No [#getEntity().entityName()#] found with constraints [#serializeJSON( this.getBindings() )#]";
			if ( isClosure( arguments.errorMessage ) || isCustomFunction( arguments.errorMessage ) ) {
				arguments.errorMessage = arguments.errorMessage( getEntity() );
			}

			throw( type = "EntityNotFound", message = arguments.errorMessage );
		}
		return instance;
	}

	/**
	 * Returns the entity with the id value as the primary key.
	 * If no record is found, it throws an `EntityNotFound` exception.
	 *
	 * @id            The id value to find.
	 * @errorMessage  An optional string error message or callback to produce
	 *                a string error message.  If a callback is used, it is
	 *                passed the unloaded entity as the only argument.
	 *
	 * @throws        EntityNotFound
	 *
	 * @return        quick.models.BaseEntity
	 */
	public any function findOrFail( required any id, any errorMessage ) {
		var instance = this.find( arguments.id );
		if ( isNull( instance ) ) {
			param arguments.errorMessage = "No [#getEntity().entityName()#] found with id [#( isArray( arguments.id ) ? arguments.id.toList() : arguments.id )#]";
			if ( isClosure( arguments.errorMessage ) || isCustomFunction( arguments.errorMessage ) ) {
				arguments.errorMessage = arguments.errorMessage( getEntity(), arguments.id );
			}

			throw( type = "EntityNotFound", message = arguments.errorMessage );
		}
		return instance;
	}

	/**
	 * Returns the first matching entity for the configured query.
	 * If no records are found, it returns null instead.
	 *
	 * @return  quick.models.BaseEntity || null
	 */
	public any function first() {
		activateGlobalScopes();

		var result = variables.qb.first();
		return structIsEmpty( result ) ? javacast( "null", "" ) : handleTransformations(
			// wrap the single entity in an array to eager load, then grab it out again
			eagerLoadRelations( [ variables._asQuery ? result : loadEntity( result ) ] )[ 1 ]
		);
	}

	/**
	 * Finds the first matching record or returns an unloaded new entity.
	 *
	 * @attributes                   A struct of attributes to restrict the query. If no entity is
	 *                               found the attributes are filled on the new entity returned.
	 * @newAttributes                A struct of attributes to fill on the new entity if no entity
	 *                               is found. These attributes are combined with `attributes`.
	 * @ignoreNonExistentAttributes  If true, does not throw an exception if an
	 *                               attribute does not exist.  Instead, it skips
	 *                               the non-existent attribute.
	 *
	 * @return                       quick.models.BaseEntity
	 */
	public any function firstOrNew(
		struct attributes                   = {},
		struct newAttributes                = {},
		boolean ignoreNonExistentAttributes = false
	) {
		try {
			for ( var key in arguments.attributes ) {
				variables.qb.where( key, arguments.attributes[ key ] );
			}
			return firstOrFail();
		} catch ( EntityNotFound e ) {
			arguments.attributes.append( arguments.newAttributes, true );
			return handleTransformations(
				getEntity().newEntity().fill( arguments.attributes, arguments.ignoreNonExistentAttributes )
			);
		}
	}

	/**
	 * Finds the first matching record or creates a new entity.
	 *
	 * @attributes                   A struct of attributes to restrict the query. If no entity is
	 *                               found the attributes are filled on the new entity created.
	 * @newAttributes                A struct of attributes to fill on the created entity if no entity
	 *                               is found. These attributes are combined with `attributes`.
	 * @ignoreNonExistentAttributes  If true, does not throw an exception if an
	 *                               attribute does not exist.  Instead, it skips
	 *                               the non-existent attribute.
	 *
	 * @return                       quick.models.BaseEntity
	 */
	public any function firstOrCreate(
		struct attributes                   = {},
		struct newAttributes                = {},
		boolean ignoreNonExistentAttributes = false
	) {
		for ( var key in arguments.attributes ) {
			variables.qb.where( key, arguments.attributes[ key ] );
		}

		try {
			return firstOrFail();
		} catch ( EntityNotFound e ) {
			arguments.attributes.append( arguments.newAttributes, true );
			return handleTransformations(
				getEntity().create( arguments.attributes, arguments.ignoreNonExistentAttributes )
			);
		}
	}

	/**
	 * Adds a basic where clause to the query and returns the first result.
	 *
	 * @column      The name of the column with which to constrain the query. A closure can be passed to begin a nested where statement.
	 * @operator    The operator to use for the constraint (i.e. "=", "<", ">=", etc.).  A value can be passed as the `operator` and the `value` left null as a shortcut for equals (e.g. where( "column", 1 ) == where( "column", "=", 1 ) ).
	 * @value       The value with which to constrain the column.  An expression (`builder.raw()`) can be passed as well.
	 * @combinator  The boolean combinator for the clause (e.g. "and" or "or"). Default: "and"
	 *
	 * @return      quick.models.BaseEntity
	 */
	public any function firstWhere(
		any column,
		any operator,
		any value,
		string combinator = "and"
	) {
		return this.where( argumentCollection = arguments ).first();
	}

	/**
	 * Returns the entity with the id value as the primary key.
	 * If no record is found, it returns a new unloaded entity.
	 *
	 * @id                           The id value to find.
	 * @attributes                   A struct of attributes to fill on the new entity if no entity is found.
	 * @ignoreNonExistentAttributes  If true, does not throw an exception if an
	 *                               attribute does not exist.  Instead, it skips
	 *                               the non-existent attribute.
	 *
	 * @return      quick.models.BaseEntity
	 */
	public any function findOrNew(
		required any id,
		struct attributes                   = {},
		boolean ignoreNonExistentAttributes = false
	) {
		try {
			return findOrFail( arguments.id );
		} catch ( EntityNotFound e ) {
			return handleTransformations(
				getEntity().newEntity().fill( arguments.attributes, arguments.ignoreNonExistentAttributes )
			);
		}
	}

	/**
	 * Returns the entity with the id value as the primary key.
	 * If no record is found, it returns a newly created entity.
	 *
	 * @id                           The id value to find.
	 * @attributes                   A struct of attributes to use when creating the new entity
	 *                               if no entity is found.
	 * @ignoreNonExistentAttributes  If true, does not throw an exception if an
	 *                               attribute does not exist.  Instead, it skips
	 *                               the non-existent attribute.
	 *
	 * @return  quick.models.BaseEntity
	 */
	public any function findOrCreate(
		required any id,
		struct attributes                   = {},
		boolean ignoreNonExistentAttributes = false
	) {
		try {
			return findOrFail( arguments.id );
		} catch ( EntityNotFound e ) {
			return handleTransformations(
				getEntity().create( arguments.attributes, arguments.ignoreNonExistentAttributes )
			);
		}
	}

	/**
	 * Returns if any entities exist with the configured query.
	 *
	 * @id      An optional id to check if it exists.
	 *
	 * @return  Boolean
	 */
	public boolean function exists( any id ) {
		activateGlobalScopes();
		if ( !isNull( arguments.id ) ) {
			arguments.id = arrayWrap( arguments.id );
			getEntity().guardAgainstKeyLengthMismatch( arguments.id );
			variables.qb.where( function( q ) {
				for ( var keyColumn in getEntity().keyColumns() ) {
					q.where( keyColumn, id[ 1 ] );
				}
			} );
		}
		return variables.qb.exists();
	}

	/**
	 * Returns true if any entities exist with the configured query.
	 * If no entities exist, it throws an EntityNotFound exception.
	 *
	 * @id            An optional id to check if it exists.
	 * @errorMessage  An optional string error message or callback to produce
	 *                a string error message.  If a callback is used, it is
	 *                passed the unloaded entity as the only argument.
	 *
	 * @throws        EntityNotFound
	 *
	 * @return        Boolean
	 */
	public boolean function existsOrFail( any id, any errorMessage ) {
		if ( !variables.exists( argumentCollection = arguments ) ) {
			param arguments.errorMessage = "No [#getEntity().entityName()#] exists with constraints [#serializeJSON( variables.qb.getBindings() )#]";
			if ( isClosure( arguments.errorMessage ) || isCustomFunction( arguments.errorMessage ) ) {
				arguments.errorMessage = arguments.errorMessage( getEntity() );
			}

			throw( type = "EntityNotFound", message = arguments.errorMessage );
		}
		return true;
	}

	/**
	 * Returns a Pagination Collection of entities.
	 *
	 * @page     The page of results to return.
	 * @maxRows  The number of rows to return.
	 *
	 * @return   A Pagination Collection object of the entities.
	 */
	public any function paginate( numeric page = 1, numeric maxRows = 25 ) {
		activateGlobalScopes();
		var p = variables.qb.paginate( arguments.page, arguments.maxRows );
		if ( !variables._asQuery ) {
			p.results = p.results.map( variables.loadEntity );
		}
		p.results = handleTransformations( eagerLoadRelations( p.results ) );
		return p;
	}

	/**
	 * Returns a Simple Pagination Collection of entities.
	 *
	 * @page     The page of results to return.
	 * @maxRows  The number of rows to return.
	 *
	 * @return   A Simple Pagination Collection object of the entities.
	 */
	public any function simplePaginate( numeric page = 1, numeric maxRows = 25 ) {
		activateGlobalScopes();
		var p = variables.qb.simplePaginate( arguments.page, arguments.maxRows );
		if ( !variables._asQuery ) {
			p.results = p.results.map( variables.loadEntity );
		}
		p.results = handleTransformations( eagerLoadRelations( p.results ) );
		return p;
	}


	/**
	 * Updates an existing record or creates a new record with the given attributes.
	 *
	 * @attributes                   A struct of attributes to restrict the query. If no entity is
	 *                               found the attributes are filled on the new entity created.
	 * @newAttributes                A struct of attributes to update on the found entity or the
	 *                               new entity if no entity is found.
	 * @ignoreNonExistentAttributes  If true, does not throw an exception if an
	 *                               attribute does not exist.  Instead, it skips
	 *                               the non-existent attribute.
	 *
	 * @return         quick.models.BaseEntity
	 */
	public any function updateOrCreate(
		struct attributes                   = {},
		struct newAttributes                = {},
		boolean ignoreNonExistentAttributes = false
	) {
		var newEntity = firstOrNew( arguments.attributes );
		return newEntity.fill( newAttributes, ignoreNonExistentAttributes ).save();
	}

	/**
	 * Forwards on the call to `updateOrCreate`.
	 *
	 * @values                       A struct of column and value pairs to update or insert.
	 * @ignoreNonExistentAttributes  If true, does not throw an exception if an
	 *                               attribute does not exist.  Instead, it skips
	 *                               the non-existent attribute.
	 *
	 * @return quick.models.BaseEntity
	 */
	public any function updateOrInsert( required struct values, boolean ignoreNonExistentAttributes = false ) {
		return updateOrCreate(
			newAttributes               = arguments.values,
			ignoreNonExistentAttributes = arguments.ignoreNonExistentAttributes
		);
	}

	/**
	 * Converts an entity or array of entities to mementos
	 * if asked for via the `asMemento` function.
	 *
	 * @return any
	 */
	private any function handleTransformations( entity ) {
		if ( !variables._asMemento ) {
			return arguments.entity;
		}

		if ( !isArray( arguments.entity ) ) {
			return arguments.entity.getMemento( argumentCollection = variables._asMementoSettings );
		}

		return arguments.entity.map( function( e ) {
			return e.getMemento( argumentCollection = variables._asMementoSettings );
		} );
	}

	/**
	 * Activates the global scopes while checking for excluded global scopes.
	 *
	 * @return  quick.models.BaseEntity
	 */
	public any function activateGlobalScopes() {
		if ( !variables._globalScopesApplied ) {
			variables._applyingGlobalScopes = true;

			if ( !variables._globalScopeExcludeAll ) {
				getEntity().applyGlobalScopes( this );
			}

			variables._applyingGlobalScopes = false;
			variables._globalScopesApplied  = true;
		}
		return this;
	}

	/**
	 * Allows a query to override one or more global scopes for one execution.
	 *
	 * @name    The name of the global scope to override. If ommited, then all global scopes with be excluded
	 *
	 * @return  quick.models.BaseEntity
	 */
	public any function withoutGlobalScope( any name ) {
		if ( !structKeyExists( arguments, "name" ) ) {
			variables._globalScopeExcludeAll = true;
			return this;
		}

		for ( var n in arrayWrap( arguments.name ) ) {
			variables._globalScopeExclusions.append( lCase( n ) );
		}
		return this;
	}

	/**
	 * Resets the configured query builder to new.
	 *
	 * @returns  quick.models.BaseEntity
	 */
	public any function resetQuery() {
		variables.qb = newQuickQB();
		return this;
	}

	/**
	 * Populates this entity's query bulider with the passed in query builder.
	 *
	 * @query    The query to use as this entity's query.
	 *
	 * @returns  quick.models.BaseEntity
	 */
	public any function populateQuery( required any query ) {
		if ( structKeyExists( arguments.query, "isQuickBuilder" ) ) {
			arguments.query = arguments.query.getQB();
		}
		variables.qb = arguments.query;
		return this;
	}

	/**
	 * Configures a new query builder and returns it.
	 *
	 * @return  quick.models.QuickBuilder
	 */
	public any function newQuery() {
		return variables._wirebox.getInstance( "QuickBuilder@quick" ).setEntity( getEntity() );
	}

	/**
	 * Configures a new query builder and returns it.
	 *
	 * @return  quick.models.QuickQB
	 */
	public any function newQuickQB() {
		return variables._wirebox
			.getInstance( "QuickQB@quick" )
			.setQuickBuilder( this )
			.setEntity( getEntity() )
			.setReturnFormat( "array" )
			.mergeDefaultOptions( getEntity().get_queryOptions() )
			.setColumnFormatter( function( column ) {
				return qualifyColumn( column );
			} )
			.from( getEntity().tableName() );
	}

	public any function retrieveQuery() {
		return variables.qb;
	}

	/**
	 * Loads up an entity with data from the database.
	 * 1. Assigns the key / value pairs.
	 * 2. Assigns the original attributes hash.
	 * 3. Marks the entity as loaded.
	 *
	 * @data    A struct of key / value pairs to load.
	 *
	 * @return  quick.models.BaseEntity
	 */
	public any function loadEntity( required struct data ) {
		if (
			getEntity().get_loadChildren()
			&&
			getEntity().isDiscriminatedParent()
			&&
			structKeyExists( arguments.data, listLast( getEntity().get_meta().localMetadata.discriminatorColumn, "." ) )
			&&
			structKeyExists(
				getEntity().getDiscriminations(),
				arguments.data[ listLast( getEntity().get_meta().localMetadata.discriminatorColumn, "." ) ]
			)
		) {
			var childClass = variables._wirebox.getInstance(
				getEntity().getDiscriminations()[
					arguments.data[ listLast( getEntity().get_meta().localMetadata.discriminatorColumn, "." ) ]
				].mapping
			);

			// add any virtual attributes present in the parent entity to child entity
			getEntity()
				.get_virtualAttributes()
				.each( function( item ) {
					childClass.appendVirtualAttribute( item );
				} );

			return childClass
				.assignAttributesData( arguments.data )
				.assignOriginalAttributes( arguments.data )
				.markLoaded();
		} else {
			return getEntity()
				.newEntity()
				.assignAttributesData( arguments.data )
				.assignOriginalAttributes( arguments.data )
				.markLoaded();
		}
	}

	/**
	 * Automatically converts the entities found from a query to mementos.
	 *
	 * @return  quick.models.BaseEntity
	 */
	public any function asMemento() {
		variables._asMemento         = true;
		variables._asQuery           = false;
		variables._asMementoSettings = arguments;
		return this;
	}

	/**
	 * Returns the results as a qb result instead of an array of entities.
	 *
	 * @return  quick.models.BaseEntity
	 */
	public any function asQuery( boolean withAliases = true ) {
		variables._asQuery     = true;
		variables._withAliases = arguments.withAliases;
		if ( variables._withAliases ) {
			var qualifiedColumns = getEntity().retrieveQualifiedColumns();
			qb.setColumns(
				qb.getColumns()
					.map( function( column ) {
						if ( !qualifiedColumns.contains( column ) ) {
							return column;
						}

						return column & " AS " & getEntity().retrieveAliasForColumn( listLast( column, "." ) );
					} )
			);
		}
		variables._asMemento = false;
		return this;
	}

	public QuickBuilder function clone() {
		var newBuilder = newQuery();
		newBuilder.setQB( variables.qb.clone() );
		newBuilder.set_applyingGlobalScopes( this.get_applyingGlobalScopes() );
		newBuilder.set_globalScopesApplied( this.get_globalScopesApplied() );
		newBuilder.set_globalScopeExcludeAll( this.get_globalScopeExcludeAll() );
		newBuilder.set_globalScopeExclusions( this.get_globalScopeExclusions() );
		newBuilder.set_eagerLoad( this.get_eagerLoad() );
		newBuilder.set_asQuery( this.get_asQuery() );
		newBuilder.set_withAliases( this.get_withAliases() );
		newBuilder.set_asMemento( this.get_asMemento() );
		newBuilder.set_asMementoSettings( this.get_asMementoSettings() );
		return newBuilder;
	}

	/**
	 * Ensures the return value is an array, either by returning an array
	 * or by returning the value wrapped in an array.
	 *
	 * @value        The value to ensure is an array.
	 *
	 * @doc_generic  any
	 * @return       [any]
	 */
	private array function arrayWrap( required any value ) {
		return isArray( arguments.value ) ? arguments.value : [ arguments.value ];
	}

}
