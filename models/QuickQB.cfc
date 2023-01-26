/**
 *  QueryBuilder super-type to add additional Quick-only features like relationship querying and ordering to qb queries.
 */
component extends="qb.models.Query.QueryBuilder" accessors="true" {

	property name="entity";
	property name="quickBuilder";

	/**
	 * Adds a basic WHERE clause to the query.
	 * If the column is an attribute on the entity, a query param struct is
	 * generated using the column's sql type, if set.
	 *
	 * @column      The name of the column with which to constrain the query.
	 *              A closure can be passed to begin a nested where statement.
	 * @operator    The operator to use for the constraint (i.e. "=", "<", ">=", etc.).
	 *              A value can be passed as the `operator` and the `value` left
	 *              null as a shortcut for equals
	 *              (e.g. where( "column", 1 ) == where( "column", "=", 1 ) ).
	 * @value       The value with which to constrain the column.
	 *              An expression (`builder.raw()`) can be passed as well.
	 * @combinator  The boolean combinator for the clause (e.g. "and" or "or"). Default: "and"
	 *
	 * @return      quick.models.QuickQB
	 */
	private QuickQB function whereBasic(
		required any column,
		required any operator,
		any value,
		string combinator = "and"
	) {
		if ( isSimpleValue( arguments.column ) && getEntity().hasAttribute( arguments.column ) ) {
			arguments.value = generateQueryParamStruct(
				column          = arguments.column,
				value           = isNull( arguments.value ) ? javacast( "null", "" ) : arguments.value,
				checkNullValues = false // where's should not be null.  `WHERE foo = NULL` will return nothing.
			);
		}
		super.whereBasic( argumentCollection = arguments );
		return this;
	}

	/**
	 * Checks for the existence of a relationship when executing the query.
	 *
	 * @relationshipName  The relationship to check.  Can also be a dot-delimited list of nested relationships.
	 * @operator          An optional operator to constrain the check.
	 * @count             An optional count to constrain the check.
	 * @negate            If true, checks for the the absence of the relationship instead of its existence.
	 *
	 * @return            quick.models.QuickQB
	 */
	public QuickQB function has(
		required string relationshipName,
		any operator,
		numeric count,
		string combinator = "and",
		boolean negate    = false
	) {
		var relation = getEntity().ignoreLoadedGuard( function() {
			return getEntity().withoutRelationshipConstraints( function() {
				return invoke( getEntity(), listFirst( relationshipName, "." ) );
			} );
		} );

		arguments.relationQuery = relation
			.addCompareConstraints()
			.clearOrders()
			.select( relation.raw( 1 ) );

		if ( listLen( arguments.relationshipName, "." ) > 1 ) {
			arguments.relationshipName = listRest( arguments.relationshipName, "." );

			if ( structKeyExists( arguments.relationQuery, "retrieveQuery" ) ) {
				arguments.relationQuery = arguments.relationQuery.retrieveQuery();
			}

			var nested = hasNested( argumentCollection = arguments );
			if ( structKeyExists( nested, "getQB" ) ) {
				nested = nested.getQB();
			}
			whereExists(
				query      = nested,
				combinator = arguments.combinator,
				negate     = arguments.negate
			);

			return this;
		}

		arguments.relationQuery.when( !isNull( arguments.operator ) && !isNull( arguments.count ), function( q ) {
			q.having( q.raw( "COUNT(*)" ), operator, count );
		} );

		if ( structKeyExists( arguments.relationQuery, "retrieveQuery" ) ) {
			arguments.relationQuery = arguments.relationQuery.retrieveQuery();
		}

		if ( structKeyExists( arguments.relationQuery, "getQB" ) ) {
			arguments.relationQuery = arguments.relationQuery.getQB();
		}

		whereExists(
			query      = arguments.relationQuery,
			combinator = arguments.combinator,
			negate     = arguments.negate
		);

		return this;
	}

	/**
	 * Checks for the existence of a relationship when executing the query.
	 *
	 * @relationshipName  The relationship to check.  Can also be a dot-delimited list of nested relationships.
	 * @operator          An optional operator to constrain the check.
	 * @count             An optional count to constrain the check.
	 * @negate            If true, checks for the the absence of the relationship instead of its existence.
	 *
	 * @return            quick.models.QuickQB
	 */
	public QuickQB function orHas(
		required string relationshipName,
		any operator,
		numeric count,
		boolean negate = false
	) {
		arguments.combinator = "or";
		return has( argumentCollection = arguments );
	}

	/**
	 * Checks for the absence of a relationship when executing the query.
	 *
	 * @relationshipName  The relationship to check.
	 * @operator          An optional operator to constrain the check.
	 * @count             An optional count to constrain the check.
	 *
	 * @return            quick.models.QuickQB
	 */
	public QuickQB function doesntHave(
		required string relationshipName,
		any operator,
		numeric count
	) {
		arguments.negate = true;
		return has( argumentCollection = arguments );
	}

	/**
	 * Checks for the absence of a relationship when executing the query using an OR combinator.
	 *
	 * @relationshipName  The relationship to check.
	 * @operator          An optional operator to constrain the check.
	 * @count             An optional count to constrain the check.
	 *
	 * @return            quick.models.QuickQB
	 */
	public QuickQB function orDoesntHave(
		required string relationshipName,
		any operator,
		numeric count
	) {
		arguments.combinator = "or";
		return doesntHave( argumentCollection = arguments );
	}

	/**
	 * Checks for the existence of a nested relationship when executing the query.
	 *
	 * @relationQuery     The currently configured existence check query.
	 * @relationshipName  The relationship to check.  Can be a dot-delimited
	 *                    list of nested relationships.
	 * @operator          An optional operator to constrain the check.
	 * @count             An optional count to constrain the check.
	 *
	 * @return            quick.models.QuickQB
	 */
	private any function hasNested(
		required any relationQuery,
		required string relationshipName,
		any operator,
		numeric count
	) {
		var relation = relationQuery
			.getEntity()
			.ignoreLoadedGuard( function() {
				return relationQuery
					.getEntity()
					.withoutRelationshipConstraints( function() {
						return invoke( relationQuery.getEntity(), listFirst( relationshipName, "." ) );
					} );
			} );

		if ( listLen( arguments.relationshipName, "." ) == 1 ) {
			var q = relation
				.addCompareConstraints()
				.when( !isNull( arguments.operator ) && !isNull( arguments.count ), function( q ) {
					q.having( q.raw( "COUNT(*)" ), operator, count );
				} );

			if ( structKeyExists( q, "retrieveQuery" ) ) {
				q = q.retrieveQuery();
			}

			if ( structKeyExists( q, "getQB" ) ) {
				q = q.getQB();
			}

			return invoke(
				arguments.relationQuery,
				"whereExists",
				{ "query" : q }
			);
		}

		var q = relation.addCompareConstraints();

		if ( structKeyExists( q, "retrieveQuery" ) ) {
			q = q.retrieveQuery();
		}

		if ( structKeyExists( q, "getQB" ) ) {
			q = q.getQB();
		}

		arguments.relationQuery = invoke(
			arguments.relationQuery,
			"whereExists",
			{ "query" : q }
		);

		var result = hasNested( argumentCollection = arguments );
		return structKeyExists( result, "getQB" ) ? result.getQB() : result;
	}

	/**
	 * Checks for the existence of a relationship when executing the query.
	 * The existence check is constrained by a closure.
	 *
	 * @relationshipName  The relationship to check.
	 * @closure           A closure to constrain the relationship check.
	 * @operator          An optional operator to constrain the check.
	 * @count             An optional count to constrain the check.
	 * @combinator        The boolean combinator for the clause (e.g. "and" or "or").
	 *                    Default: "and"
	 * @negate            If true, use `whereNotExists` instead of `whereExists`.
	 *
	 * @return            quick.models.QuickQB
	 */
	public QuickQB function whereHas(
		required string relationshipName,
		required any callback,
		any operator,
		any count,
		string combinator = "and",
		boolean negate    = false
	) {
		var relation = getEntity().ignoreLoadedGuard( function() {
			return getEntity().withoutRelationshipConstraints( function() {
				return invoke( getEntity(), listFirst( relationshipName, "." ) );
			} );
		} );

		arguments.relationQuery = relation.addCompareConstraints( nested = true ).clearOrders();

		if ( listLen( arguments.relationshipName, "." ) > 1 ) {
			arguments.relationshipName = listRest( arguments.relationshipName, "." );

			if ( structKeyExists( arguments.relationQuery, "getQB" ) ) {
				arguments.relationQuery = arguments.relationQuery.getQB();
			}

			var nestedQuery = whereHasNested( argumentCollection = arguments );

			if ( structKeyExists( nestedQuery, "getQB" ) ) {
				nestedQuery = nestedQuery.getQB();
			}

			whereExists(
				query      = nestedQuery,
				combinator = arguments.combinator,
				negate     = arguments.negate
			);

			return this;
		}

		var q = arguments.relationQuery
			.when( !isNull( callback ), function( q ) {
				callback( q );
			} )
			.when( !isNull( arguments.operator ) && !isNull( arguments.count ), function( q ) {
				q.having( q.raw( "COUNT(*)" ), operator, count );
			} );

		if ( structKeyExists( q, "retrieveQuery" ) ) {
			q = q.retrieveQuery();
		}

		if ( structKeyExists( q, "getQB" ) ) {
			q = q.getQB();
		}

		whereExists(
			query      = q,
			combinator = arguments.combinator,
			negate     = arguments.negate
		);

		return this;
	}

	/**
	 * Checks for the absence of a relationship when executing the query.
	 * The absence check is constrained by a closure.
	 *
	 * @relationshipName  The relationship to check.
	 * @closure           A closure to constrain the relationship check.
	 * @operator          An optional operator to constrain the check.
	 * @count             An optional count to constrain the check.
	 * @combinator        The boolean combinator for the clause (e.g. "and" or "or").
	 *                    Default: "and"
	 *
	 * @return            quick.models.QuickQB
	 */
	public QuickQB function whereDoesntHave(
		required string relationshipName,
		required any callback,
		any operator,
		any count,
		string combinator = "and"
	) {
		arguments.negate = true;
		return whereHas( argumentCollection = arguments );
	}

	/**
	 * Checks for the existence of a nested relationship.
	 *
	 * @relationQuery     The currently configured query for the existence check.
	 * @relationshipName  The rest of the relationship name to check.
	 * @callback          An optional callback to configured the last nested relation.
	 * @operator          An optional operator to constrain the check.
	 * @count             An optional count to constrain the check.
	 *
	 * @return            quick.models.QuickQB
	 */
	private QuickQB function whereHasNested(
		required any relationQuery,
		required string relationshipName,
		any callback,
		any operator,
		numeric count
	) {
		var relation = arguments.relationQuery
			.getEntity()
			.ignoreLoadedGuard( function() {
				return relationQuery
					.getEntity()
					.withoutRelationshipConstraints( function() {
						return invoke( relationQuery.getEntity(), listFirst( relationshipName, "." ) );
					} );
			} );

		if ( listLen( arguments.relationshipName, "." ) == 1 ) {
			var q = relation
				.addCompareConstraints( nested = arguments.relationQuery )
				.clearOrders()
				.when( !isNull( callback ), function( q ) {
					callback( q );
				} )
				.when( !isNull( arguments.operator ) && !isNull( arguments.count ), function( q ) {
					q.having( q.raw( "COUNT(*)" ), operator, count );
				} );

			if ( structKeyExists( q, "retrieveQuery" ) ) {
				q = q.retrieveQuery();
			}

			var result = relation.nestCompareConstraints( base = arguments.relationQuery, nested = q );

			return structKeyExists( result, "getQB" ) ? result.getQB() : result;
		}

		var q = relation.addCompareConstraints().clearOrders();

		if ( structKeyExists( q, "retrieveQuery" ) ) {
			q = q.retrieveQuery();
		}

		if ( structKeyExists( q, "getQB" ) ) {
			q = q.getQB();
		}

		var result = relation.nestCompareConstraints(
			base   = arguments.relationQuery,
			nested = whereHasNested(
				relationQuery    = q,
				relationshipName = listRest( arguments.relationshipName, "." ),
				callback         = structKeyExists( arguments, "callback" ) ? arguments.callback : javacast( "null", "" ),
				operator         = structKeyExists( arguments, "operator" ) ? arguments.operator : javacast( "null", "" ),
				count            = structKeyExists( arguments, "count" ) ? arguments.count : javacast( "null", "" )
			)
		);

		return structKeyExists( result, "getQB" ) ? result.getQB() : result;
	}

	/**
	 * Checks for the existence of a relationship when executing the query.
	 * The existence check is constrained by a closure.
	 * This method uses the "or" combinator.
	 *
	 * @relationshipName  The relationship to check.
	 * @closure           A closure to constrain the relationship check.
	 * @operator          An optional operator to constrain the check.
	 * @count             An optional count to constrain the check.
	 *
	 * @return            quick.models.QuickQB
	 */
	public QuickQB function orWhereHas(
		required string relationshipName,
		required any callback,
		any operator,
		any count
	) {
		arguments.combinator = "or";
		return whereHas( argumentCollection = arguments );
	}

	/**
	 * Checks for the absence of a relationship when executing the query.
	 * The absence check is constrained by a closure.
	 * This method uses the "or" combinator.
	 *
	 * @relationshipName  The relationship to check.
	 * @closure           A closure to constrain the relationship check.
	 * @operator          An optional operator to constrain the check.
	 * @count             An optional count to constrain the check.
	 *
	 * @return            quick.models.QuickQB
	 */
	public QuickQB function orWhereDoesntHave(
		required string relationshipName,
		required any callback,
		any operator,
		any count
	) {
		arguments.combinator = "or";
		return whereDoesntHave( argumentCollection = arguments );
	}

	/**
	 * Adds a single order by clause to the query.
	 * Overloaded to proxy to `orderByRelated` when a relationship is found.
	 *
	 * @column     The name of the column(s) to order by.
	 * @direction  The direction by which to order the query.  Accepts "asc" OR "desc". Default: "asc".
	 *
	 * @return     quick.models.QuickQB
	 */
	private QuickQB function orderBySingle( required any column, string direction = "asc" ) {
		if (
			// if this isn't a normal struct with a column key...
			(
				isStruct( arguments.column ) &&
				(
					isObject( arguments.column ) ||
					!structKeyExists( arguments.column, "column" )
				)
			) &&
			// or a simple value...
			!isSimpleValue( arguments.column )
		) {
			// then delegate to qb
			return super.orderBySingle( argumentCollection = arguments );
		}

		// if this is a struct, destructure it to our arguments
		if ( isStruct( arguments.column ) ) {
			if ( arguments.column.keyExists( "direction" ) ) {
				arguments.direction = arguments.column.direction;
			}

			arguments.column = arguments.column.column;
		}

		if ( listLen( arguments.column, "." ) <= 1 ) {
			return super.orderBySingle( argumentCollection = arguments );
		}

		if ( !getEntity().hasRelationship( listFirst( arguments.column, "." ) ) ) {
			return super.orderBySingle( argumentCollection = arguments );
		}

		return getQuickBuilder()
			.orderByRelated(
				listSlice( arguments.column, 1, -1, "." ),
				listLast( arguments.column, "." ),
				arguments.direction
			)
			.getQB();
	}

	/**
	 * Returns a query param struct for the column and value.
	 * This ensures that custom sql types on columns are honored.
	 *
	 * @column  The column or alias name.
	 * @value   The value being bound to the column.
	 *
	 * @return  { "value": any, "cfsqltype": string, "null": boolean, "nulls": boolean }
	 */
	public struct function generateQueryParamStruct(
		required string column,
		any value,
		boolean checkNullValues = true
	) {
		// If that value is already a struct, pass it back unchanged.
		if ( !isNull( arguments.value ) && isStruct( arguments.value ) ) {
			return arguments.value;
		}

		if ( arguments.checkNullValues ) {
			return {
				"value"     : ( isNull( arguments.value ) || getEntity().isNullValue( arguments.column, arguments.value ) ) ? "" : arguments.value,
				"cfsqltype" : getEntity().attributeHasSqlType( arguments.column ) ? getEntity().retrieveSqlTypeForAttribute(
					arguments.column
				) : ( isNull( arguments.value ) ? "CF_SQL_VARCHAR" : getUtils().inferSqlType( arguments.value ) ),
				"null"  : isNull( arguments.value ) || getEntity().isNullValue( arguments.column, arguments.value ),
				"nulls" : isNull( arguments.value ) || getEntity().isNullValue( arguments.column, arguments.value )
			};
		} else {
			return {
				"value"     : isNull( arguments.value ) ? "" : arguments.value,
				"cfsqltype" : getEntity().attributeHasSqlType( arguments.column ) ? getEntity().retrieveSqlTypeForAttribute(
					arguments.column
				) : ( isNull( arguments.value ) ? "CF_SQL_VARCHAR" : getUtils().inferSqlType( arguments.value ) ),
				"null"  : isNull( arguments.value ),
				"nulls" : isNull( arguments.value )
			};
		}
	}

	/**
	 * Slices an array from an offset for a given length.
	 * Similar to arraySlice
	 *
	 * @list        The list to slice.
	 * @offset      Start position in the original list to slice.
	 * @length      Number of elements to slice from offset.
	 * @delimiters  Characters that separate list elements. The default value is comma.
	 */
	private string function listSlice(
		required string list,
		numeric offset    = 1,
		numeric length    = listLen( list ),
		string delimiters = ","
	) {
		if ( arguments.length < 0 ) {
			arguments.length = listLen( arguments.list, arguments.delimiters ) + arguments.length;
		}

		return arguments.list
			.listToArray( arguments.delimiters )
			.slice( arguments.offset, arguments.length )
			.toList( arguments.delimiters );
	}

	/**
	 * Creates a new query using the same Grammar and QueryUtils.
	 *
	 * @return qb.models.Query.QueryBuilder
	 */
	public QueryBuilder function newQuery() {
		var newBuilder = new quick.models.QuickQB(
			grammar             = getGrammar(),
			utils               = getUtils(),
			returnFormat        = getReturnFormat(),
			paginationCollector = isNull( variables.paginationCollector ) ? javacast( "null", "" ) : variables.paginationCollector,
			columnFormatter     = isNull( getColumnFormatter() ) ? javacast( "null", "" ) : getColumnFormatter(),
			parentQuery         = isNull( getParentQuery() ) ? javacast( "null", "" ) : getParentQuery(),
			defaultOptions      = getDefaultOptions()
		);
		newBuilder.setQuickBuilder( getQuickBuilder() );
		newBuilder.setEntity( getEntity() );
		newBuilder.setFrom( getFrom() );
		return newBuilder;
	}

	/**
	 * Trys scopes before forwarding on to qb's onMissingMethod
	 *
	 * @return any
	 */
	public any function onMissingMethod( string missingMethodName, struct missingMethodArguments ) {
		var result = getEntity().tryScopes(
			arguments.missingMethodName,
			arguments.missingMethodArguments,
			getQuickBuilder()
		);

		if ( !isNull( result ) ) {
			// If a query is returned, set it as the current query and return
			// the entity. Otherwise return whatever came back from the scope.
			if (
				isStruct( result ) &&
				( structKeyExists( result, "retrieveQuery" ) || structKeyExists( result, "isBuilder" ) )
			) {
				return this;
			}

			return result;
		}

		return super.onMissingMethod( argumentCollection = arguments );
	}

	// override's super impl
	// keep in sync with `super.whereNested`, or merge them somehow
	public QueryBuilder function whereNested( required callback, combinator = "and" ) {
        // We descend into a new QueryBuilder, but it is not an isolated thing and requires a fresh context,
        // but it will by default inherit the current context.
        // "relevant context" is assumed to be exactly "the available QueryBuilder object", we can push/pop it.

        var query = forNestedWhere();                  // common with super
		var saved_QB = this.getQuickBuilder().getQB(); // unique to this
        this.getQuickBuilder().setQB( query );           // unique to this
        callback( query );                             // common with super
        this.getQuickBuilder().setQB( saved_QB );        // unique to this

        return addNestedWhereQuery( query, combinator ); // common with super
    }
}
