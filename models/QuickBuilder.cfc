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
	 * A flag marking if this builder prevent the results from lazy loading relationships. Default: false.
	 */
	property
		name   ="_preventLazyLoading"
		default="false"
		inject ="box:setting:preventLazyLoading@quick";

	/**
	 * A callback function called when a lazy loading violation occurs.
	 * It is passed the entity and relation name that caused the violation.
	 */
	property name="_lazyLoadingViolationCallback" inject="box:setting:lazyLoadingViolationCallback@quick";

	/**
	 * The maximum number of eager-loading workers that may run at once.
	 */
	property
		name   ="_parallelEagerLoadingMaxThreads"
		default="4"
		inject ="box:setting:parallelEagerLoadingMaxThreads@quick";

	/**
	 * The number of milliseconds to wait for a batch of eager-loading workers.
	 */
	property
		name   ="_parallelEagerLoadingTimeout"
		default="60000"
		inject ="box:setting:parallelEagerLoadingTimeout@quick";

	/**
	 * Thread-local lifecycle state shared by every QuickBuilder instance.
	 */
	property name="_parallelEagerLoadingContext" inject="quick.models.ParallelEagerLoadingContext";

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
	 * Callbacks applied to each hydrated entity before return transformations.
	 */
	property name="_entityTransformers";

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
		variables._eagerLoad                            = [];
		variables._parallelEagerLoading                 = false;
		variables._globalScopesApplied                  = false;
		variables._globalScopeExcludeAll                = false;
		variables._asMemento                            = false;
		variables._asQuery                              = false;
		variables._withAliases                          = false;
		variables._entityTransformers                   = [];
		param variables._parallelEagerLoadingMaxThreads = 4;
		param variables._parallelEagerLoadingTimeout    = 60000;
		param variables._preventLazyLoading             = false;
		if ( !variables.keyExists( "_lazyLoadingViolationCallback" ) || isNull( variables._lazyLoadingViolationCallback ) ) {
			variables._lazyLoadingViolationCallback = ( entity, relationName ) => {
				throw(
					type    = "QuickLazyLoadingException",
					message = "Attempted to lazy load the [#arguments.relationName#] relationship on the entity [#arguments.entity.mappingName()#] but lazy loading is disabled. This is usually caused by the N+1 problem and is a sign that you are missing an eager load."
				);
			};
		}
		variables._asMementoSettings     = {};
		variables._globalScopeExclusions = [];
		variables.aliasMap               = {};
		return this;
	}

	/**
	 * Adds a callback that transforms each hydrated entity before it is returned.
	 *
	 * @transformer  The callback accepting and returning an entity.
	 *
	 * @return       quick.models.QuickBuilder
	 */
	public QuickBuilder function addEntityTransformer( required any transformer ) {
		variables._entityTransformers.append( arguments.transformer );
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
	 * Resolves a relationship without allocating nested guard callbacks.
	 */
	private any function resolveRelationship(
		required any entity,
		required string relationshipName,
		boolean withoutConstraints = true
	) {
		arguments.entity.set_ignoreNotLoadedGuard( true );
		if ( arguments.withoutConstraints ) {
			arguments.entity.get_withoutRelationshipConstraints().add( lCase( arguments.relationshipName ) );
		}
		try {
			return invoke( arguments.entity, arguments.relationshipName );
		} finally {
			arguments.entity.set_ignoreNotLoadedGuard( false );
			if ( arguments.withoutConstraints ) {
				arguments.entity.get_withoutRelationshipConstraints().remove( lCase( arguments.relationshipName ) );
			}
		}
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
		variables.aliasMap[ arguments.alias ] = getEntity();
		getEntity().withAlias( arguments.alias );
		variables.qb.withAlias( arguments.alias );
		return this;
	}

	private void function ensureKeyColumnsSelected() {
		var selectedColumns = variables.qb.getColumns();
		for ( var column in selectedColumns ) {
			if ( column.type == "simple" && column.value.find( "*" ) ) {
				return;
			}
		}

		for ( var keyColumn in getEntity().keyColumns() ) {
			var qualifiedKey = getEntity().qualifyColumn( keyColumn );
			var hasKey       = false;
			for ( var column in selectedColumns ) {
				if ( column.type == "simple" && compareNoCase( column.value, qualifiedKey ) == 0 ) {
					hasKey = true;
					break;
				}
			}
			if ( !hasKey ) {
				variables.qb.addSelect( qualifiedKey );
			}
		}
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
			variables.qb.select( variables.qb.getTableName() & ".*" );
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
					q = resolveRelationship( getEntity(), relationshipName ).addCompareConstraints();
				} else {
					var relationship = resolveRelationship( q.getEntity(), relationshipName );
					q.select( q.raw( 1 ) );
					if ( isStruct( qb ) && structKeyExists( qb, "isQuickBuilder" ) ) {
						q.getQB();
					}
					var relationshipQuery = relationship.addCompareConstraints( q );
					if ( isStruct( relationshipQuery ) && structKeyExists( relationshipQuery, "getRelationshipBuilder" ) ) {
						relationshipQuery = relationshipQuery.getRelationshipBuilder();
					}
					if ( isStruct( relationshipQuery ) && structKeyExists( relationshipQuery, "isQuickBuilder" ) ) {
						relationshipQuery = relationshipQuery.getQB();
					}
					q = relationship.whereExists( relationshipQuery );
				}
				column = listRest( column, "." );
			}
			subselectQuery = q.select( q.qualifyColumn( column ) );
		}

		subselectQuery.limit( 1 )

		if ( isStruct( subselectQuery ) && structKeyExists( subselectQuery, "getRelationshipBuilder" ) ) {
			subselectQuery = subselectQuery.getRelationshipBuilder();
		}

		if ( isStruct( subselectQuery ) && structKeyExists( subselectQuery, "isQuickBuilder" ) ) {
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
		variables.qb = variables.qb.join( argumentCollection = arguments );
		if ( isStruct( arguments.table ) ) {
			var joinedBuilder = javacast( "null", "" );
			if ( structKeyExists( arguments.table, "isQuickBuilder" ) ) {
				joinedBuilder = arguments.table;
			} else if ( structKeyExists( arguments.table, "getQuickBuilder" ) ) {
				joinedBuilder = arguments.table.getQuickBuilder();
			}
			if ( !isNull( joinedBuilder ) ) {
				variables.aliasMap[ joinedBuilder.tableAlias() ] = joinedBuilder.getEntity();
			}
		}
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
			var callback     = "";
			var hasCallback  = false;

			if ( isStruct( r ) ) {
				for ( var key in r ) {
					relationName = key;
					callback     = r[ key ];
					hasCallback  = true;
					break;
				}
			}

			var subselectNameArray = getEntity().get_str().words( relationName );
			subselectNameArray.append( "Count" );

			var subselectName = getEntity().get_str().camel( subselectNameArray.toList( " " ) );
			if ( findNoCase( " as ", relationName ) ) {
				var parts     = relationName.split( "\s(?:A|a)(?:S|s)\s" );
				relationName  = parts[ 1 ];
				subselectName = parts[ 2 ];
			}

			var countBuilder = resolveRelationship( getEntity(), relationName ).addCompareConstraints();
			if ( hasCallback ) {
				countBuilder.when( true, callback );
			}
			countBuilder.clearOrders().reselectRaw( "COUNT(*)" );

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
			var callback     = "";
			var hasCallback  = false;

			if ( isStruct( relationName ) ) {
				for ( var key in relationName ) {
					callback     = relationName[ key ];
					relationName = key;
					hasCallback  = true;
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

			var subselectNameArray = [ "Total" ];
			subselectNameArray.append( getEntity().get_str().words( relationName ), true );

			var subselectName = getEntity().get_str().camel( subselectNameArray.toList( " " ) );
			if ( findNoCase( " as ", attributeName ) ) {
				var parts     = attributeName.split( "\s(?:A|a)(?:S|s)\s" );
				attributeName = parts[ 1 ];
				subselectName = parts[ 2 ];
			}

			var related    = resolveRelationship( getEntity(), relationName );
			var sumBuilder = related.addCompareConstraints();
			if ( hasCallback ) {
				sumBuilder.when( true, callback );
			}
			sumBuilder.clearOrders().reselectRaw( "COALESCE(SUM(#related.qualifyColumn( attributeName )#), 0)" );

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
	 * @columns  An optional column, list of columns, or array of columns to select.
	 *           The selected columns before calling get will be restored after running the query.
	 * @options  Any options to pass to `queryExecute`. Default: {}.
	 *
	 * @doc_generic  quick.models.BaseEntity
	 * @return       [quick.models.BaseEntity]
	 */
	private array function getEntities( any columns, struct options = {} ) {
		if ( !variables._asQuery ) {
			ensureKeyColumnsSelected();
		}
		var results = variables.qb.get( argumentCollection = arguments );
		if ( variables._asQuery ) {
			return results;
		}
		var refreshQuery = variables.qb.clone();
		var entities     = [];
		for ( var result in results ) {
			entities.append( variables.loadEntity( result, refreshQuery ) );
		}
		return entities;
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
		return getEntity().newCollection(
			handleTransformations( eagerLoadRelations( getEntities( argumentCollection = arguments ) ) )
		);
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
		return variables.qb.update( prepareBulkMutationAttributes( arguments.attributes ) );
	}

	/**
	 * Inserts rows that do not exist and updates rows matching the target columns.
	 *
	 * Like `updateAll`, this is a bulk mutation. It applies Quick attribute metadata
	 * and read-only guards, but does not hydrate entities or fire per-entity events.
	 *
	 * @values          The values to insert or the columns selected by the source query.
	 * @target          The columns used to determine whether a row already exists.
	 * @update          The columns or explicit values to update when a row matches.
	 * @source          An optional query builder or callback used as the source rows.
	 * @deleteUnmatched Whether to delete target rows missing from the source, or a callback constraining those deletes.
	 * @options         Options passed to `queryExecute`.
	 * @toSql           Whether to return SQL instead of executing the query.
	 * @matchNulls      Whether two NULL target values should be considered a match. Supported by MERGE grammars.
	 * @force           If true, skips read-only entity and read-only attribute checks.
	 *
	 * @throws          QuickReadOnlyException
	 *
	 * @return          The qb bulk execution result, or SQL when `toSql` is true.
	 */
	public any function upsert(
		required any values,
		required any target,
		any update,
		any source,
		any deleteUnmatched = false,
		struct options      = {},
		boolean toSql       = false,
		boolean matchNulls  = false,
		boolean force       = false
	) {
		if ( !arguments.force ) {
			getEntity().guardReadOnly();
			guardBulkMutationAttributes( arguments.values );
			if ( structKeyExists( arguments, "update" ) ) {
				guardBulkMutationAttributes( arguments.update );
			}
		}

		arguments.values = prepareBulkMutationValues( arguments.values );
		if ( structKeyExists( arguments, "update" ) && isStruct( arguments.update ) ) {
			arguments.update = prepareBulkMutationAttributes( arguments.update );
		}

		structDelete( arguments, "force" );
		return variables.qb.upsert( argumentCollection = arguments );
	}

	/**
	 * Applies Quick query parameter metadata to a bulk mutation attribute struct.
	 */
	private struct function prepareBulkMutationAttributes( required struct attributes ) {
		var preparedAttributes = {};
		for ( var key in arguments.attributes ) {
			preparedAttributes[ key ] = getEntity().generateQueryParamStruct(
				column = key,
				value  = isNull( arguments.attributes[ key ] ) ? javacast( "null", "" ) : arguments.attributes[ key ]
			);
		}
		return preparedAttributes;
	}

	/**
	 * Applies Quick query parameter metadata to literal upsert rows.
	 */
	private any function prepareBulkMutationValues( required any values ) {
		if ( isArray( arguments.values ) ) {
			var preparedValues = [];
			for ( var value in arguments.values ) {
				preparedValues.append( isStruct( value ) ? prepareBulkMutationAttributes( value ) : value );
			}
			return preparedValues;
		}

		if (
			isStruct( arguments.values ) &&
			!structKeyExists( arguments.values, "isBuilder" ) &&
			!structKeyExists( arguments.values, "isQuickBuilder" )
		) {
			return prepareBulkMutationAttributes( arguments.values );
		}

		return arguments.values;
	}

	/**
	 * Guards literal rows or column collections used by a bulk mutation.
	 */
	private void function guardBulkMutationAttributes( required any attributes ) {
		if ( isArray( arguments.attributes ) ) {
			for ( var item in arguments.attributes ) {
				guardBulkMutationAttributes( item );
			}
			return;
		}

		if (
			isStruct( arguments.attributes ) &&
			!structKeyExists( arguments.attributes, "isBuilder" ) &&
			!structKeyExists( arguments.attributes, "isQuickBuilder" )
		) {
			getEntity().guardAgainstReadOnlyAttributes( arguments.attributes );
			return;
		}

		if ( isSimpleValue( arguments.attributes ) ) {
			for ( var attribute in listToArray( arguments.attributes ) ) {
				getEntity().guardAgainstReadOnlyAttributes( { "#attribute#" : true } );
			}
		}
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
		if ( !arguments.condition && isNull( arguments.onFalse ) ) {
			return this;
		}
		var selectedCallback = arguments.condition ? arguments.onTrue : arguments.onFalse;

		if ( arguments.withoutScoping ) {
			selectedCallback( this );
		} else {
			var originalWhereCount = variables.qb.getWheres().len();
			selectedCallback( this );
			groupNewWheresForScope( originalWhereCount );
		}

		return this;
	}

	/**
	 * Groups OR predicates added by a callback using qb's nested-query objects.
	 */
	private void function groupNewWheresForScope( required numeric originalWhereCount ) {
		if ( variables.qb.getWheres().len() <= arguments.originalWhereCount ) {
			return;
		}
		var allWheres = variables.qb.getWheres();
		variables.qb.setWheres( [] );
		if ( arguments.originalWhereCount > 0 ) {
			appendScopedWhereSlice(
				arraySlice(
					allWheres,
					1,
					arguments.originalWhereCount
				)
			);
		}
		appendScopedWhereSlice( arraySlice( allWheres, arguments.originalWhereCount + 1 ) );
	}

	private void function appendScopedWhereSlice( required array whereSlice ) {
		for ( var whereClause in arguments.whereSlice ) {
			if ( compareNoCase( whereClause.combinator, "OR" ) == 0 ) {
				variables.qb.addNestedWhereQuery( variables.qb.forNestedWhere().setWheres( arguments.whereSlice ) );
				return;
			}
		}
		var wheres = variables.qb.getWheres();
		wheres.append( arguments.whereSlice, true );
		variables.qb.setWheres( wheres );
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
			var idConstraints = variables.qb.forNestedWhere();
			for ( var id in arguments.ids ) {
				var values = arrayWrap( id );
				getEntity().guardAgainstKeyLengthMismatch( values );
				var keyConstraints = idConstraints.forNestedWhere();
				var keyNames       = getEntity().keyNames();
				for ( var i = 1; i <= keyNames.len(); i++ ) {
					keyConstraints.where( keyNames[ i ], values[ i ] );
				}
				idConstraints.addNestedWhereQuery( keyConstraints, "or" );
			}
			variables.qb.addNestedWhereQuery( idConstraints );
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
	 * @parallel      If true, eager loads top-level relationships concurrently.
	 *
	 * @return        QuickBuilder
	 */
	public any function with( required any relationName, boolean parallel = false ) {
		if ( isSimpleValue( arguments.relationName ) && arguments.relationName == "" ) {
			return this;
		}

		arrayAppend(
			variables._eagerLoad,
			arrayWrap( arguments.relationName ),
			true
		);
		variables._parallelEagerLoading = variables._parallelEagerLoading || arguments.parallel;

		return this;
	}

	/**
	 * Removes one or more relationships from the eager-load list. Omitting the
	 * argument leaves the eager-load list unchanged.
	 *
	 * @relationName A relationship name or array of relationship names to remove.
	 *
	 * @return       QuickBuilder
	 */
	public any function without( any relationName ) {
		if ( isNull( arguments.relationName ) ) {
			return this;
		}

		var exclusions    = arrayWrap( arguments.relationName );
		var eagerLoadList = [];
		for ( var eagerLoad in variables._eagerLoad ) {
			var path       = isStruct( eagerLoad ) ? eagerLoad.keyArray()[ 1 ] : eagerLoad;
			var isExcluded = false;
			for ( var exclusion in exclusions ) {
				if (
					compareNoCase( path, exclusion ) == 0 ||
					compareNoCase( left( path, len( exclusion ) + 1 ), exclusion & "." ) == 0
				) {
					isExcluded = true;
					break;
				}
			}
			if ( !isExcluded ) {
				eagerLoadList.append( eagerLoad );
			}
		}
		variables._eagerLoad = eagerLoadList;
		return this;
	}

	/**
	 * Removes every configured eager load.
	 *
	 * @return QuickBuilder
	 */
	public any function clearEagerLoads() {
		variables._eagerLoad = [];
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
		var grammar = getEntity().newQuery().getGrammar();
		if ( structKeyExists( grammar, "parameterLimit" ) ) {
			var parameterLimit = grammar.parameterLimit;
			if ( parameterLimit > 0 && arguments.entities.len() > parameterLimit ) {
				for ( var i = 1; i < arguments.entities.len(); i += parameterLimit ) {
					var length = min( arguments.entities.len() - i + 1, parameterLimit );
					var slice  = arraySlice( arguments.entities, i, length );
					eagerLoadRelations( slice );
				}
				return arguments.entities;
			}
		}

		var eagerLoads = denestEagerLoads( variables._eagerLoad );
		if ( variables._parallelEagerLoading && eagerLoads.count() > 1 && supportsParallelEagerLoading() ) {
			eagerLoadRelationsInParallel( eagerLoads, arguments.entities );
		} else {
			for ( var relationName in eagerLoads ) {
				arguments.entities = eagerLoadRelation(
					relationName,
					eagerLoads[ relationName ],
					arguments.entities
				);
			}
		}

		return arguments.entities;
	}

	/**
	 * Eager loads independent top-level relationships on separate threads.
	 */
	private void function eagerLoadRelationsInParallel( required struct eagerLoads, required array entities ) {
		var relationNames  = arguments.eagerLoads.keyArray();
		var maxWorkers     = max( 1, int( variables._parallelEagerLoadingMaxThreads ) );
		var timeout        = max( 1, int( variables._parallelEagerLoadingTimeout ) );
		var targetEntities = arguments.entities;
		var threadResults  = createObject( "java", "java.util.concurrent.ConcurrentHashMap" ).init();
		var entityStates   = [];
		for ( var entity in arguments.entities ) {
			entityStates.append(
				structKeyExists( entity, "isQuickEntity" )
				 ? {
					"isQuickEntity" : true,
					"mappingName"   : entity.mappingName(),
					"attributes"    : entity.retrieveAttributesData( withNulls = true )
				}
				 : {
					"isQuickEntity" : false,
					"value"         : duplicate( entity )
				}
			);
		}

		for ( var batchStart = 1; batchStart <= relationNames.len(); batchStart += maxWorkers ) {
			var batchThreadNames     = [];
			var batchThreadRelations = {};
			var batchEnd             = min( relationNames.len(), batchStart + maxWorkers - 1 );
			for ( var relationIndex = batchStart; relationIndex <= batchEnd; relationIndex++ ) {
				var relationName = relationNames[ relationIndex ];
				var threadName   = "quick_eager_#replace( createUUID(), "-", "", "all" )#";
				batchThreadNames.append( threadName );
				batchThreadRelations[ threadName ] = relationName;
				cfthread(
					action          = "run",
					name            = threadName,
					threadName      = threadName,
					relationName    = relationName,
					eagerLoadConfig = arguments.eagerLoads[ relationName ],
					entityStates    = entityStates,
					results         = threadResults
				) {
					variables._parallelEagerLoadingContext.suppressLifecycleEvents();
					try {
						var workerEntities = [];
						for ( var entityState in attributes.entityStates ) {
							workerEntities.append(
								entityState.isQuickEntity
								 ? hydrateParallelEntityState( entityState )
								 : entityState.value
							);
						}
						var loadedEntities = eagerLoadRelation(
							attributes.relationName,
							attributes.eagerLoadConfig,
							workerEntities
						);
						var relationshipValues = [];
						for ( var loadedEntity in loadedEntities ) {
							if ( structKeyExists( loadedEntity, "isQuickEntity" ) ) {
								if ( isNull( loadedEntity.retrieveRelationship( attributes.relationName ) ) ) {
									relationshipValues.append( { "type" : "null" } );
								} else {
									relationshipValues.append(
										serializeParallelValue(
											loadedEntity.retrieveRelationship( attributes.relationName )
										)
									);
								}
							} else if ( loadedEntity.keyExists( attributes.relationName ) ) {
								relationshipValues.append(
									serializeParallelValue( loadedEntity[ attributes.relationName ] )
								);
							} else {
								relationshipValues.append( { "type" : "null" } );
							}
						}
						attributes.results.put( attributes.threadName, relationshipValues );
					} finally {
						variables._parallelEagerLoadingContext.restoreLifecycleEvents();
					}
				}
			}

			cfthread(
				action  = "join",
				name    = batchThreadNames.toList(),
				timeout = timeout
			);

			var failedThread = "";
			var timedOut     = false;
			for ( var batchThreadName in batchThreadNames ) {
				if ( cfthread[ batchThreadName ].status == "TERMINATED" && failedThread == "" ) {
					failedThread = batchThreadName;
				}
				if (
					cfthread[ batchThreadName ].status != "COMPLETED" && cfthread[ batchThreadName ].status != "TERMINATED"
				) {
					timedOut = true;
				}
			}
			if ( failedThread != "" || timedOut ) {
				terminateParallelEagerLoadingThreads( batchThreadNames );
			}
			if ( failedThread != "" ) {
				var threadError = cfthread[ failedThread ].error;
				throw(
					type         = "QuickParallelEagerLoadingException",
					message      = threadError.keyExists( "message" ) ? threadError.message : "A parallel eager-loading thread failed.",
					extendedInfo = serializeJSON( threadError )
				);
			}
			if ( timedOut ) {
				throw(
					type    = "QuickParallelEagerLoadingTimeout",
					message = "Parallel eager loading did not complete within #timeout# milliseconds."
				);
			}

			for ( var completedThreadName in batchThreadNames ) {
				var completedRelationName = batchThreadRelations[ completedThreadName ];
				var relationshipValues    = threadResults.get( completedThreadName );
				for ( var i = 1; i <= targetEntities.len(); i++ ) {
					var completedRelationshipValue = deserializeParallelValue( relationshipValues[ i ] );
					if ( structKeyExists( targetEntities[ i ], "isQuickEntity" ) ) {
						if ( isNull( completedRelationshipValue ) ) {
							targetEntities[ i ].assignRelationship( completedRelationName );
						} else {
							targetEntities[ i ].assignRelationship( completedRelationName, completedRelationshipValue );
						}
						targetEntities[ i ].fireRelationshipLoaded( completedRelationName );
					} else if ( !isNull( completedRelationshipValue ) ) {
						targetEntities[ i ][ completedRelationName ] = completedRelationshipValue;
					}
				}
			}
		}
	}

	private any function hydrateParallelEntityState( required struct state ) {
		return getEntity()
			.newEntity( arguments.state.mappingName )
			.assignAttributesData( arguments.state.attributes )
			.assignOriginalAttributes( arguments.state.attributes )
			.set_loaded( true );
	}

	private void function terminateParallelEagerLoadingThreads( required array threadNames ) {
		for ( var threadName in arguments.threadNames ) {
			if ( cfthread[ threadName ].status != "COMPLETED" && cfthread[ threadName ].status != "TERMINATED" ) {
				cfthread( action = "terminate", name = threadName );
			}
		}
	}

	/**
	 * Converts eager-loaded values to CFC-free state for crossing thread boundaries.
	 */
	private struct function serializeParallelValue( any value ) {
		if ( isNull( arguments.value ) ) {
			return { "type" : "null" };
		}
		if ( isArray( arguments.value ) ) {
			var items = [];
			for ( var item in arguments.value ) {
				items.append( serializeParallelValue( item ) );
			}
			return { "type" : "array", "value" : items };
		}
		if ( isStruct( arguments.value ) && structKeyExists( arguments.value, "isQuickEntity" ) ) {
			var relationships = {};
			for ( var relationshipName in arguments.value.get_relationshipsLoaded().keyArray() ) {
				relationships[ relationshipName ] = serializeParallelValue(
					arguments.value.retrieveRelationship( relationshipName )
				);
			}
			return {
				"type"          : "entity",
				"mappingName"   : arguments.value.mappingName(),
				"attributes"    : arguments.value.retrieveAttributesData( withNulls = true ),
				"relationships" : relationships
			};
		}
		if ( isStruct( arguments.value ) ) {
			var values = {};
			for ( var key in arguments.value ) {
				values[ key ] = serializeParallelValue( arguments.value[ key ] );
			}
			return { "type" : "struct", "value" : values };
		}
		return {
			"type"  : "value",
			"value" : arguments.value
		};
	}

	/**
	 * Reconstructs eager-loaded values exported by a worker thread.
	 */
	private any function deserializeParallelValue( required struct state ) {
		switch ( arguments.state.type ) {
			case "null":
				return javacast( "null", "" );
			case "array":
				var items = [];
				for ( var item in arguments.state.value ) {
					items.append( deserializeParallelValue( item ) );
				}
				return items;
			case "entity":
				var entity = getEntity().newEntity( arguments.state.mappingName );
				try {
					entity.hydrate( arguments.state.attributes );
				} catch ( MissingHydrationKey missingKey ) {
					entity
						.assignAttributesData( arguments.state.attributes )
						.assignOriginalAttributes( arguments.state.attributes )
						.set_loaded( true );
				}
				for ( var relationshipName in arguments.state.relationships ) {
					var relationshipValue = deserializeParallelValue(
						arguments.state.relationships[ relationshipName ]
					);
					if ( isNull( relationshipValue ) ) {
						entity.assignRelationship( relationshipName );
					} else {
						entity.assignRelationship( relationshipName, relationshipValue );
					}
					entity.fireRelationshipLoaded( relationshipName );
				}
				return entity;
			case "struct":
				var values = {};
				for ( var key in arguments.state.value ) {
					var value = deserializeParallelValue( arguments.state.value[ key ] );
					if ( !isNull( value ) ) {
						values[ key ] = value;
					}
				}
				return values;
			default:
				return arguments.state.value;
		}
	}

	/**
	 * Adobe ColdFusion loses CFC private-method resolution inside cfthread.
	 */
	private boolean function supportsParallelEagerLoading() {
		return !server.keyExists( "coldfusion" ) || !findNoCase( "ColdFusion", server.coldfusion.productName );
	}

	private struct function denestEagerLoads( required array eagerLoads ) {
		// this comes in as an array of items which can be:
		// 1. dot-delimited strings (e.g., "videos.tags")
		// 2. structs with the key being the dot-delimited path and the value being a callback
		// these dot-delimited strings can have the same parent
		// we want to only load each relationship and its eager loads once
		// Result format: { "relationName": { "callback": function, "nested": { ... } } }
		var result = {};

		for ( var relationshipPath in arguments.eagerLoads ) {
			var callbackConfig = { "present" : false };
			var pathString     = "";

			// Handle struct format: { "path.to.relation": callback }
			if ( isStruct( relationshipPath ) ) {
				for ( var key in relationshipPath ) {
					pathString             = key;
					callbackConfig.present = isCustomFunction( relationshipPath[ key ] ) || isClosure(
						relationshipPath[ key ]
					);
					if ( callbackConfig.present ) {
						callbackConfig.value = relationshipPath[ key ];
					}
					break;
				}
			} else {
				pathString = relationshipPath;
			}

			var parts     = listToArray( pathString, "." );
			var firstPart = parts[ 1 ];

			// Initialize the entry if it doesn't exist
			if ( !result.keyExists( firstPart ) ) {
				result[ firstPart ] = { "nested" : {} };
			}

			if ( parts.len() > 1 ) {
				// Build the nested path with the callback attached to the deepest level
				var nestedPath = arraySlice( parts, 2 ).toList( "." );
				var nestedItem = callbackConfig.present ? { "#nestedPath#" : callbackConfig.value } : nestedPath;

				var nestedResult                = denestEagerLoads( [ nestedItem ] );
				// Merge nested results
				result[ firstPart ][ "nested" ] = mergeNestedEagerLoads( result[ firstPart ][ "nested" ], nestedResult );
			} else {
				// This is the target level - apply the callback here
				if ( callbackConfig.present ) {
					result[ firstPart ][ "callback" ] = callbackConfig.value;
				}
			}
		}

		return result;
	}

	private struct function mergeNestedEagerLoads( required struct target, required struct source ) {
		for ( var key in arguments.source ) {
			if ( !arguments.target.keyExists( key ) ) {
				arguments.target[ key ] = arguments.source[ key ];
			} else {
				// Merge callbacks - source callback takes precedence if it's not empty
				if (
					structKeyExists( arguments.source[ key ], "callback" ) &&
					(
						isCustomFunction( arguments.source[ key ][ "callback" ] ) || isClosure(
							arguments.source[ key ][ "callback" ]
						)
					)
				) {
					// Check if source callback has a body (not empty)
					arguments.target[ key ][ "callback" ] = arguments.source[ key ][ "callback" ];
				}
				// Merge nested
				if ( structKeyExists( arguments.source[ key ], "nested" ) ) {
					arguments.target[ key ][ "nested" ] = mergeNestedEagerLoads(
						arguments.target[ key ][ "nested" ],
						arguments.source[ key ][ "nested" ]
					);
				}
			}
		}
		return arguments.target;
	}

	public array function renestEagerLoads( required struct additionalEagerLoads ) {
		// Input format: { "relationName": { "callback": fn, "nested": { ... } } }
		// Output format: array of strings or structs like { "path.to.relation": callback }
		var eagerLoads = [];
		for ( var relationName in arguments.additionalEagerLoads ) {
			var eagerLoadConfig = arguments.additionalEagerLoads[ relationName ];
			var hasCallback     = eagerLoadConfig.keyExists( "callback" ) && (
				isCustomFunction( eagerLoadConfig.callback ) || isClosure( eagerLoadConfig.callback )
			);
			var nestedConfig = {};
			if ( eagerLoadConfig.keyExists( "nested" ) ) {
				nestedConfig = eagerLoadConfig.nested;
			}
			// Get the renested items from nested config
			var nestedItems = renestEagerLoads( nestedConfig );

			if ( nestedItems.len() > 0 ) {
				// There are nested items - prepend this relationName to each
				for ( var nestedItem in nestedItems ) {
					if ( isSimpleValue( nestedItem ) ) {
						eagerLoads.append( relationName & "." & nestedItem );
					} else {
						// It's a struct with callback - prepend relationName to the key
						for ( var key in nestedItem ) {
							eagerLoads.append( { "#relationName#.#key#" : nestedItem[ key ] } );
							break;
						}
					}
				}
			} else if ( hasCallback ) {
				// No nested, but has a callback - return as struct
				eagerLoads.append( { "#relationName#" : eagerLoadConfig.callback } );
			} else {
				// No nested, no callback - just the relation name
				eagerLoads.append( relationName );
			}
		}
		return eagerLoads;
	}

	/**
	 * Eager loads the given relation for the retrieved entities.
	 * Returns the retrieved entities eager loaded with the given relation.
	 *
	 * @relationName       The relationship to eager load.
	 * @eagerLoadConfig    The config for this eager load containing callback and nested eager loads.
	 * @entities           The retrieved entities or array of structs to eager load the relationship.
	 *
	 * @doc_generic   quick.models.BaseEntity | struct
	 * @return        [quick.models.BaseEntity] | [struct]
	 */
	private array function eagerLoadRelation(
		required string relationName,
		required struct eagerLoadConfig,
		required array entities
	) {
		// Extract callback and nested config from the eagerLoadConfig
		var nestedEagerLoads = {};
		if ( arguments.eagerLoadConfig.keyExists( "nested" ) ) {
			nestedEagerLoads = arguments.eagerLoadConfig.nested;
		}

		var relation = resolveRelationship( getEntity(), relationName );
		if ( arguments.eagerLoadConfig.keyExists( "callback" ) ) {
			arguments.eagerLoadConfig.callback( relation );
		}
		var hasMatches = relation.addEagerConstraints( arguments.entities, getEntity() );
		relation.with( renestEagerLoads( nestedEagerLoads ) );
		var matchedEntities = relation.match(
			relation.initRelation( arguments.entities, arguments.relationName ),
			hasMatches ? relation.getEager( variables._asQuery, variables._withAliases ) : [],
			arguments.relationName
		);
		var loadedRelationshipName = arguments.relationName;
		for ( var entity in matchedEntities ) {
			if (
				!variables._parallelEagerLoadingContext.areLifecycleEventsSuppressed()
				&& isStruct( entity )
				&& structKeyExists( entity, "isQuickEntity" )
			) {
				entity.fireRelationshipLoaded( loadedRelationshipName );
			}
		}
		return matchedEntities;
	}

	/**
	 * Marks the results as not being allowed to lazy load relationships.
	 *
	 * @return  quick.models.QuickBuilder
	 */
	public QuickBuilder function preventLazyLoading() {
		variables._preventLazyLoading = true;
		return this;
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
				q = resolveRelationship( getEntity(), thisRelationshipName ).addCompareConstraints().clearOrders();
			} else {
				var relationship = resolveRelationship( q.getEntity(), thisRelationshipName );

				var existsQuery = relationship.addCompareConstraints( q.select( q.raw( 1 ) ) ).clearOrders();

				if ( isStruct( existsQuery ) && structKeyExists( existsQuery, "isQuickBuilder" ) ) {
					existsQuery = existsQuery.getQB();
				}

				q = relationship.whereExists( existsQuery );
			}
			arguments.relationshipName = listRest( arguments.relationshipName, "." );
		}

		q.select( arguments.columnName );

		if ( isStruct( q ) && structKeyExists( q, "relationshipClass" ) ) {
			q = q.retrieveQuery();
		}

		if ( isStruct( q ) && structKeyExists( q, "isQuickBuilder" ) ) {
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
		if ( !structKeyExists( arguments, "tableName" ) || isNull( arguments.tableName ) ) {
			return getEntity().qualifyColumn( arguments.column );
		}
		return getEntity().qualifyColumn( argumentCollection = arguments );
	}

	/**
	 * Qualifies a column using the current table for the provided query.
	 *
	 * @column The column to qualify.
	 * @query  The query whose current table should be used.
	 *
	 * @return string
	 */
	public string function qualifyColumnForQuery( required string column, required any query ) {
		var tableName = arguments.query.getTableName();
		if ( arguments.query.getAlias() != "" ) {
			tableName = arguments.query.getAlias();
		}
		return !isNull( tableName ) && isSimpleValue( tableName ) && tableName != ""
		 ? qualifyColumn( arguments.column, tableName )
		 : qualifyColumn( arguments.column );
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

	function applyInheritanceJoins() {
		var entity = getEntity();
		// Apply and append any inheritance joins/columns
		if ( entity.hasParentEntity() && !entity.isSingleTableInheritance() ) {
			var parentDefinition = entity.getParentDefinition();
			var parentEntity     = variables._wirebox.getInstance( parentDefinition.meta.fullName )
			variables.qb.join(
				parentDefinition.meta.table,
				parentEntity.qualifyColumn( parentDefinition.key ),
				entity.qualifyColumn( entity.keyNames()[ 1 ] )
			);
		} else if ( entity.isDiscriminatedParent() && entity.get_loadChildren() ) {
			for ( var discriminator in entity.getDiscriminations() ) {
				var data = entity.getDiscriminations()[ discriminator ];
				// only join if this is a polymorphic association
				if ( !entity.isSingleTableInheritance() ) {
					variables.qb.join(
						data.table,
						getEntity().qualifyColumn( getEntity().keyNames()[ 1 ] ),
						"=",
						data.joincolumn,
						"left outer"
					);
				}
				var childColumns = [];
				for ( var column in data.childColumns ) {
					childColumns.append( column == data.joincolumn ? "#column# AS #column#" : column );
				}
				variables.qb.addSelect( childColumns );
			}
		}
	}

	/**
	 * Creates a virtual attribute for the given name.
	 *
	 * @name                The attribute name to create.
	 * @defaultValue        The default value for the virtual attribute.
	 * @excludeFromMemento  Whether to exclude the virtual attribute from mementos.
	 *
	 * @return  quick.models.BaseEntity
	 */
	public any function appendVirtualAttribute(
		required string name,
		any defaultValue,
		boolean excludeFromMemento = false
	) {
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

		throw(
			type    = "QuickMissingMethod",
			message = arrayToList(
				[
					"Quick couldn't figure out what to do with [#arguments.missingMethodName#].",
					"We tried checking columns, aliases, scopes, and relationships locally.",
					"We also forwarded the call on to qb to see if it could do anything with it, but it couldn't."
				],
				" "
			)
		);
	}

	/**
	 * Returns the entity with the id value as the primary key.
	 * If no record is found, it returns null instead.
	 *
	 * @id      The id value to find.
	 * @options Any options to pass to `queryExecute`. Default: {}.
	 *
	 * @return  quick.models.BaseEntity || null
	 */
	public any function find( required any id, struct options = {} ) {
		arguments.id = arrayWrap( arguments.id );
		getEntity().guardAgainstKeyLengthMismatch( arguments.id );
		getEntity().fireEvent(
			"preLoad",
			{
				"id"       : arguments.id,
				"metadata" : getEntity().get_meta(),
				"options"  : arguments.options
			}
		);
		activateGlobalScopes();
		var idQuery     = variables.qb.forNestedWhere();
		var allKeyNames = getEntity().keyNames();
		for ( var i = 1; i <= allKeyNames.len(); i++ ) {
			idQuery.where( allKeyNames[ i ], arguments.id[ i ] );
		}
		variables.qb.addNestedWhereQuery( idQuery, "and" );
		return this.first( arguments.options );
	}

	/**
	 * Returns the first matching entity for the configured query.
	 * If no records are found, it throws an `EntityNotFound` exception.
	 *
	 * @errorMessage  An optional string error message or callback to produce
	 *                a string error message.  If a callback is used, it is
	 *                passed the unloaded entity as the only argument.
	 * @options       Any options to pass to `queryExecute`. Default: {}.
	 *
	 * @throws        EntityNotFound
	 *
	 * @return        quick.models.BaseEntity
	 */
	public any function firstOrFail( any errorMessage, struct options = {} ) {
		activateGlobalScopes();
		var instance = this.first( arguments.options );
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
	 * @options       Any options to pass to `queryExecute`. Default: {}.
	 *
	 * @throws        EntityNotFound
	 *
	 * @return        quick.models.BaseEntity
	 */
	public any function findOrFail(
		required any id,
		any errorMessage,
		struct options = {}
	) {
		var instance = this.find( arguments.id, arguments.options );
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
	 * @options Any options to pass to `queryExecute`. Default: {}.
	 *
	 * @return  quick.models.BaseEntity || null
	 */
	public any function first( struct options = {} ) {
		activateGlobalScopes();
		if ( !variables._asQuery ) {
			ensureKeyColumnsSelected();
		}

		var result = variables.qb.first( argumentCollection = arguments );
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
	 * @options                      Any options to pass to `queryExecute`. Default: {}.
	 *
	 * @return                       quick.models.BaseEntity
	 */
	public any function firstOrNew(
		struct attributes                   = {},
		struct newAttributes                = {},
		boolean ignoreNonExistentAttributes = false,
		struct options                      = {}
	) {
		try {
			for ( var key in arguments.attributes ) {
				variables.qb.where( key, arguments.attributes[ key ] );
			}
			return firstOrFail( options = arguments.options );
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
	 * @options                      Any options to pass to `queryExecute`. Default: {}.
	 *
	 * @return                       quick.models.BaseEntity
	 */
	public any function firstOrCreate(
		struct attributes                   = {},
		struct newAttributes                = {},
		boolean ignoreNonExistentAttributes = false,
		struct options                      = {}
	) {
		for ( var key in arguments.attributes ) {
			variables.qb.where( key, arguments.attributes[ key ] );
		}

		try {
			return firstOrFail( options = arguments.options );
		} catch ( EntityNotFound e ) {
			arguments.attributes.append( arguments.newAttributes, true );
			return handleTransformations(
				getEntity().create(
					arguments.attributes,
					arguments.ignoreNonExistentAttributes,
					arguments.options
				)
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
	 * @options Any options to pass to `queryExecute`. Default: {}.
	 *
	 * @return      quick.models.BaseEntity
	 */
	public any function firstWhere(
		any column,
		any operator,
		any value,
		string combinator = "and",
		struct options    = {}
	) {
		return this.where( argumentCollection = arguments ).first( arguments.options );
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
	 * @options                      Any options to pass to `queryExecute`. Default: {}.
	 *
	 * @return      quick.models.BaseEntity
	 */
	public any function findOrNew(
		required any id,
		struct attributes                   = {},
		boolean ignoreNonExistentAttributes = false,
		struct options                      = {}
	) {
		try {
			return findOrFail( id = arguments.id, options = arguments.options );
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
	 * @options                      Any options to pass to `queryExecute`. Default: {}.
	 *
	 * @return  quick.models.BaseEntity
	 */
	public any function findOrCreate(
		required any id,
		struct attributes                   = {},
		boolean ignoreNonExistentAttributes = false,
		struct options                      = {}
	) {
		try {
			return findOrFail( id = arguments.id, options = arguments.options );
		} catch ( EntityNotFound e ) {
			return handleTransformations(
				getEntity().create(
					arguments.attributes,
					arguments.ignoreNonExistentAttributes,
					arguments.options
				)
			);
		}
	}

	/**
	 * Returns if any entities exist with the configured query.
	 *
	 * @id      An optional id to check if it exists.
	 * @options Any options to pass to `queryExecute`. Default: {}.
	 *
	 * @return  Boolean
	 */
	public boolean function exists( any id, struct options = {} ) {
		activateGlobalScopes();
		if ( !isNull( arguments.id ) ) {
			arguments.id = arrayWrap( arguments.id );
			getEntity().guardAgainstKeyLengthMismatch( arguments.id );
			var keyConstraints = variables.qb.forNestedWhere();
			for ( var keyColumn in getEntity().keyColumns() ) {
				keyConstraints.where( keyColumn, arguments.id[ 1 ] );
			}
			variables.qb.addNestedWhereQuery( keyConstraints );
		}
		return variables.qb.exists( arguments.options );
	}

	/**
	 * Returns true if any entities exist with the configured query.
	 * If no entities exist, it throws an EntityNotFound exception.
	 *
	 * @id            An optional id to check if it exists.
	 * @errorMessage  An optional string error message or callback to produce
	 *                a string error message.  If a callback is used, it is
	 *                passed the unloaded entity as the only argument.
	 * @options       Any options to pass to `queryExecute`. Default: {}.
	 *
	 * @throws        EntityNotFound
	 *
	 * @return        Boolean
	 */
	public boolean function existsOrFail(
		any id,
		any errorMessage,
		struct options = {}
	) {
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
	 * Retrieves the configured query in chunks and passes hydrated entities to
	 * the callback. Returning false from the callback stops further retrieval.
	 *
	 * @max      The maximum number of entities in each chunk.
	 * @callback The callback invoked for each entity collection.
	 * @options  Any options to pass to `queryExecute`. Default: {}.
	 *
	 * @return   quick.models.QuickBuilder
	 */
	public any function chunk(
		required numeric max,
		required callback,
		struct options = {}
	) {
		if ( arguments.max <= 0 ) {
			throw( type = "InvalidChunkSize", message = "Chunk size must be greater than zero." );
		}
		activateGlobalScopes();
		var rowOffset = 0;
		while ( true ) {
			var rows = variables.qb
				.limit( arguments.max )
				.offset( rowOffset )
				.get( options = arguments.options );
			if ( rows.len() == 0 ) {
				break;
			}
			var entities = rows;
			if ( !variables._asQuery ) {
				entities = [];
				for ( var row in rows ) {
					entities.append( variables.loadEntity( row ) );
				}
			}
			var collection     = getEntity().newCollection( handleTransformations( eagerLoadRelations( entities ) ) );
			var shouldContinue = arguments.callback( collection );
			if ( ( !isNull( shouldContinue ) && !shouldContinue ) || rows.len() < arguments.max ) {
				break;
			}
			rowOffset += arguments.max;
		}
		return this;
	}

	/**
	 * Returns a Pagination Collection of entities.
	 *
	 * @page     The page of results to return.
	 * @maxRows  The number of rows to return.
	 * @options  Any options to pass to `queryExecute`. Default: {}.
	 *
	 * @return   A Pagination Collection object of the entities.
	 */
	public any function paginate(
		numeric page    = 1,
		numeric maxRows = 25,
		struct options  = {}
	) {
		activateGlobalScopes();
		if ( !variables._asQuery ) {
			ensureKeyColumnsSelected();
		}
		var p = variables.qb.paginate(
			arguments.page,
			arguments.maxRows,
			arguments.options
		);
		if ( !variables._asQuery ) {
			var entities = [];
			for ( var result in p.results ) {
				entities.append( variables.loadEntity( result ) );
			}
			p.results = entities;
		}
		p.results = handleTransformations( eagerLoadRelations( p.results ) );
		return p;
	}

	/**
	 * Returns a Simple Pagination Collection of entities.
	 *
	 * @page     The page of results to return.
	 * @maxRows  The number of rows to return.
	 * @options  Any options to pass to `queryExecute`. Default: {}.
	 *
	 * @return   A Simple Pagination Collection object of the entities.
	 */
	public any function simplePaginate(
		numeric page    = 1,
		numeric maxRows = 25,
		struct options  = {}
	) {
		activateGlobalScopes();
		if ( !variables._asQuery ) {
			ensureKeyColumnsSelected();
		}
		var p = variables.qb.simplePaginate(
			arguments.page,
			arguments.maxRows,
			arguments.options
		);
		if ( !variables._asQuery ) {
			var entities = [];
			for ( var result in p.results ) {
				entities.append( variables.loadEntity( result ) );
			}
			p.results = entities;
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
	 * @options                      Any options to pass to `queryExecute`. Default: {}.
	 *
	 * @return         quick.models.BaseEntity
	 */
	public any function updateOrCreate(
		struct attributes                   = {},
		struct newAttributes                = {},
		boolean ignoreNonExistentAttributes = false,
		struct options                      = {}
	) {
		var newEntity = firstOrNew( attributes = arguments.attributes, options = arguments.options );
		return newEntity.fill( newAttributes, ignoreNonExistentAttributes ).save( arguments.options );
	}

	/**
	 * Forwards on the call to `updateOrCreate`.
	 *
	 * @values                       A struct of column and value pairs to update or insert.
	 * @ignoreNonExistentAttributes  If true, does not throw an exception if an
	 *                               attribute does not exist.  Instead, it skips
	 *                               the non-existent attribute.
	 * @options                      Any options to pass to `queryExecute`. Default: {}.
	 *
	 * @return quick.models.BaseEntity
	 */
	public any function updateOrInsert(
		required struct values,
		boolean ignoreNonExistentAttributes = false,
		struct options                      = {}
	) {
		return updateOrCreate(
			newAttributes               = arguments.values,
			ignoreNonExistentAttributes = arguments.ignoreNonExistentAttributes,
			options                     = arguments.options
		);
	}

	/**
	 * Converts an entity or array of entities to mementos
	 * if asked for via the `asMemento` function.
	 *
	 * @return any
	 */
	private any function handleTransformations( entity ) {
		if ( !variables._asQuery ) {
			if ( isArray( arguments.entity ) ) {
				var transformedEntities = [];
				for ( var item in arguments.entity ) {
					transformedEntities.append( applyEntityTransformers( item ) );
				}
				arguments.entity = transformedEntities;
			} else if ( !isNull( arguments.entity ) ) {
				arguments.entity = applyEntityTransformers( arguments.entity );
			}
		}

		if ( !variables._asMemento ) {
			return arguments.entity;
		}

		if ( !isArray( arguments.entity ) ) {
			return arguments.entity.getMemento( argumentCollection = variables._asMementoSettings );
		}

		var mementos = [];
		for ( var resultEntity in arguments.entity ) {
			mementos.append( resultEntity.getMemento( argumentCollection = variables._asMementoSettings ) );
		}
		return mementos;
	}

	/**
	 * Applies all configured entity transformers to one hydrated entity.
	 */
	private any function applyEntityTransformers( required any entity ) {
		var transformed = arguments.entity;
		for ( var transformer in variables._entityTransformers ) {
			transformed = transformer( transformed );
		}
		return transformed;
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
		if ( !structKeyExists( arguments, "name" ) || isNull( arguments.name ) ) {
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
		if ( isStruct( arguments.query ) && structKeyExists( arguments.query, "isQuickBuilder" ) ) {
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
	public any function loadEntity( required struct data, any refreshQuery ) {
		var loadedData     = arguments.data;
		var hasVirtualData = false;
		for ( var attribute in getEntity().get_virtualAttributes() ) {
			if ( loadedData.keyExists( attribute ) ) {
				hasVirtualData = true;
				break;
			}
		}
		if ( hasVirtualData && isNull( arguments.refreshQuery ) ) {
			arguments.refreshQuery = variables.qb.clone();
		}

		if (
			getEntity().get_loadChildren()
			&&
			getEntity().isDiscriminatedParent()
			&&
			structKeyExists( arguments.data, listLast( getEntity().discriminatorColumn(), "." ) )
			&&
			structKeyExists(
				getEntity().getDiscriminations(),
				arguments.data[ listLast( getEntity().discriminatorColumn(), "." ) ]
			)
		) {
			var discrimination = getEntity().getDiscriminations()[
				arguments.data[ listLast( getEntity().discriminatorColumn(), "." ) ]
			];

			var childClass = variables._wirebox.getInstance( discrimination.mapping );

			// add any virtual attributes present in the parent entity to child entity
			for ( var item in getEntity().get_virtualAttributes() ) {
				childClass.appendVirtualAttribute( item );
			}

			// find the correct child columns to use, in the case that multiple child tables contain the same column
			for ( var column in data ) {
				if ( listLen( column, "." ) > 1 ) {
					if ( listFirst( column, "." ) == discrimination.table ) {
						data[ listRest( column, "." ) ] = data[ column ];
						data.delete( column );
					} else {
						// if the column is not in the discrimination table, then we need to remove it
						data.delete( column );
					}
				}
			}

			var childEntity = childClass
				.assignAttributesData( arguments.data )
				.assignOriginalAttributes( arguments.data )
				.set_preventLazyLoading( variables._preventLazyLoading )
				.set_lazyLoadingViolationCallback( variables._lazyLoadingViolationCallback );
			markLoadedEntity( childEntity );
			if ( hasVirtualData ) {
				childEntity.set_refreshQuery( arguments.refreshQuery );
			}
			return childEntity;
		} else {
			var entity = getEntity()
				.newEntity()
				.assignAttributesData( arguments.data )
				.assignOriginalAttributes( arguments.data )
				.set_preventLazyLoading( variables._preventLazyLoading )
				.set_lazyLoadingViolationCallback( variables._lazyLoadingViolationCallback );
			markLoadedEntity( entity );
			if ( hasVirtualData ) {
				entity.set_refreshQuery( arguments.refreshQuery );
			}
			return entity;
		}
	}

	private void function markLoadedEntity( required any entity ) {
		if ( variables._parallelEagerLoadingContext.areLifecycleEventsSuppressed() ) {
			arguments.entity.set_loaded( true );
		} else {
			arguments.entity.markLoaded();
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
			var columns          = [];
			for ( var column in qb.getColumns() ) {
				if (
					column.type != "raw" &&
					column.type != "builder" &&
					qualifiedColumns.contains( column.value )
				) {
					columns.append( {
						"type"  : "simple",
						"value" : column.value & " AS " & getEntity().retrieveAliasForColumn(
							listLast( column.value, "." )
						)
					} );
				} else {
					columns.append( column );
				}
			}
			qb.setColumns( columns );
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
		newBuilder.set_preventLazyLoading( this.get_preventLazyLoading() );
		newBuilder.set_lazyLoadingViolationCallback( this.get_lazyLoadingViolationCallback() );
		newBuilder.set_withAliases( this.get_withAliases() );
		newBuilder.set_asMemento( this.get_asMemento() );
		newBuilder.set_asMementoSettings( this.get_asMementoSettings() );
		newBuilder.set_entityTransformers( this.get_entityTransformers() );
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

	/**
	 * Accepts an array of arrays and calls a callback passing each item of
	 * the same index from each of the arrays.
	 *
	 * @arrays    An array of arrays.  All arrays must have the same length.
	 * @callback  The callback to call.  It will be passed an item from each
	 *            array passed in at the same index.
	 *
	 * @throws    ArrayZipLengthMismatch
	 *
	 * @return    The original array of arrays passed in.
	 */
	private array function arrayZipEach( required array arrays, required any callback ) {
		if ( arguments.arrays.isEmpty() ) {
			return arguments.arrays;
		}

		var lengths = [];
		for ( var arr in arguments.arrays ) {
			lengths.append( arr.len() );
		}

		if ( unique( lengths ).len() > 1 ) {
			throw(
				type         = "ArrayZipLengthMismatch",
				message      = "The arrays do not have the same length. Lengths: [#serializeJSON( lengths )#]",
				extendedInfo = serializeJSON( arguments.arrays )
			);
		}

		for ( var i = 1; i <= arguments.arrays[ 1 ].len(); i++ ) {
			var args = {};
			for ( var j = 1; j <= arguments.arrays.len(); j++ ) {
				args[ j ] = arguments.arrays[ j ][ i ];
			}
			callback( argumentCollection = args );
		}

		return arguments.arrays;
	}

	/**
	 * Returns an array of the unique items of an array.
	 *
	 * @items        An array of items.
	 *
	 * @doc_generic  any
	 * @return       [any]
	 */
	public array function unique( required array items ) {
		if ( arrayIsEmpty( arguments.items ) ) {
			return arguments.items;
		}

		return arraySlice( createObject( "java", "java.util.HashSet" ).init( arguments.items ).toArray(), 1 );
	}

}
