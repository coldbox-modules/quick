component extends="qb.models.Query.QueryBuilder" accessors="true" {

	/**
	 * The entity associated with this builder.
	 */
	property name="entity";

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
	 * @return      quick.models.QuickBuilder
	 */
	private QuickBuilder function whereBasic(
		required string column,
		required string operator,
		any value,
		string combinator = "and"
	) {
		if ( getEntity().hasAttribute( arguments.column ) ) {
			arguments.value = getEntity().generateQueryParamStruct(
				column          = arguments.column,
				value           = isNull( arguments.value ) ? javacast( "null", "" ) : arguments.value,
				checkNullValues = false // where's should not be null.  `WHERE foo = NULL` will return nothing.
			);
		}
		super.whereBasic( argumentCollection = arguments );
		return this;
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
		getEntity().activateGlobalScopes();
		return super.get( argumentCollection = arguments );
	}

	/**
	 * Updates a table with a struct of column and value pairs.
	 * This call must come after setting the query's table using `from` or `table`.
	 * Any constraining of the update query should be done using the appropriate WHERE statement before calling `update`.
	 *
	 * @values   A struct of column and value pairs to update.
	 * @options  Any options to pass to `queryExecute`. Default: {}.
	 * @toSql    If true, returns the raw sql string instead of running the query.
	 *           Useful for debugging. Default: false.
	 *
	 * @return   query
	 */
	public any function update(
		struct values  = {},
		struct options = {},
		boolean toSql  = false
	) {
		getEntity().activateGlobalScopes();
		return super.update( argumentCollection = arguments );
	}

	/**
	 * Deletes a record set.
	 * This call must come after setting the query's table using `from` or `table`.
	 * Any constraining of the update query should be done using the appropriate WHERE statement before calling `update`.
	 *
	 * @id            A convenience argument for `where( "id", "=", arguments.id ).
	 *                The query can be constrained by normal WHERE methods
	 *                if you have more complex needs.
	 * @idColumnName  The name of the id column for the delete shorthand. Default: "id".
	 * @options       Any options to pass to `queryExecute`. Default: {}.
	 * @toSql         If true, returns the raw sql string instead of running
	 *                the query. Useful for debugging. Default: false.
	 *
	 * @return        any
	 */
	public any function delete(
		any id,
		string idColumnName = "id",
		struct options      = {},
		boolean toSql       = false
	) {
		getEntity().activateGlobalScopes();
		return super.delete( argumentCollection = arguments );
	}

	/**
	 * Updates matching entities with the given attributes
	 * according to the configured query.
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
		return update(
			arguments.attributes.map( function( key, value ) {
				return getEntity().generateQueryParamStruct(
					column = key,
					value  = isNull( value ) ? javacast( "null", "" ) : value
				);
			} )
		);
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
			where( function( q1 ) {
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
		return delete();
	}

	/**
	 * Checks for the existence of a relationship when executing the query.
	 *
	 * @relationshipName  The relationship to check.
	 * @operator          An optional operator to constrain the check.
	 * @count             An optional count to constrain the check.
	 *
	 * @return            quick.models.QuickBuilder
	 */
	public QuickBuilder function has(
		required string relationshipName,
		string operator,
		numeric count,
		boolean negate = false
	) {
		var methodName = arguments.negate ? "whereNotExists" : "whereExists";
		var relation   = getEntity().withoutRelationshipConstraints( function() {
			return invoke( getEntity(), listFirst( relationshipName, "." ) );
		} );

		arguments.relationQuery = relation.addCompareConstraints().select( relation.raw( 1 ) );

		if ( listLen( arguments.relationshipName, "." ) > 1 ) {
			arguments.relationshipName = listRest( arguments.relationshipName, "." );

			if ( structKeyExists( arguments.relationQuery, "retrieveQuery" ) ) {
				arguments.relationQuery = arguments.relationQuery.retrieveQuery();
			}

			invoke(
				this,
				methodName,
				{ "query" : hasNested( argumentCollection = arguments ) }
			);

			return this;
		}

		arguments.relationQuery.when( !isNull( arguments.operator ) && !isNull( arguments.count ), function( q ) {
			q.having( q.raw( "COUNT(*)" ), operator, count );
		} );

		if ( structKeyExists( arguments.relationQuery, "retrieveQuery" ) ) {
			arguments.relationQuery = arguments.relationQuery.retrieveQuery();
		}

		invoke(
			this,
			methodName,
			{ "query" : arguments.relationQuery }
		);

		return this;
	}

	/**
	 * Checks for the absence of a relationship when executing the query.
	 *
	 * @relationshipName  The relationship to check.
	 * @operator          An optional operator to constrain the check.
	 * @count             An optional count to constrain the check.
	 *
	 * @return            quick.models.QuickBuilder
	 */
	public QuickBuilder function doesntHave(
		required string relationshipName,
		string operator,
		numeric count
	) {
		arguments.negate = true;
		return has( argumentCollection = arguments );
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
	 * @return            quick.models.QuickBuilder
	 */
	private any function hasNested(
		required any relationQuery,
		required string relationshipName,
		string operator,
		numeric count
	) {
		var relation = relationQuery
			.getEntity()
			.withoutRelationshipConstraints( function() {
				return invoke( relationQuery.getEntity(), listFirst( relationshipName, "." ) );
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

		arguments.relationQuery = invoke(
			arguments.relationQuery,
			"whereExists",
			{ "query" : q }
		);

		return hasNested( argumentCollection = arguments );
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
	 * @return            quick.models.QuickBuilder
	 */
	public QuickBuilder function whereHas(
		required string relationshipName,
		any callback,
		any operator,
		any count,
		string combinator = "and",
		boolean negate    = false
	) {
		var methodName = arguments.negate ? "whereNotExists" : "whereExists";
		var relation   = getEntity().withoutRelationshipConstraints( function() {
			return invoke( getEntity(), listFirst( relationshipName, "." ) );
		} );

		arguments.relationQuery = relation.addCompareConstraints();

		if ( listLen( arguments.relationshipName, "." ) > 1 ) {
			arguments.relationshipName = listRest( arguments.relationshipName, "." );

			if ( structKeyExists( arguments.relationQuery, "retrieveQuery" ) ) {
				arguments.relationQuery = arguments.relationQuery.retrieveQuery();
			}

			invoke(
				this,
				methodName,
				{ "query" : whereHasNested( argumentCollection = arguments ) }
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

		invoke(
			this,
			methodName,
			{
				"query"      : q,
				"combinator" : arguments.combinator
			}
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
	 * @return            quick.models.QuickBuilder
	 */
	public QuickBuilder function whereDoesntHave(
		required string relationshipName,
		any callback,
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
	 * @return            quick.models.QuickBuilder
	 */
	private QuickBuilder function whereHasNested(
		required any relationQuery,
		required string relationshipName,
		any callback,
		string operator,
		numeric count
	) {
		var relation = arguments.relationQuery
			.getEntity()
			.withoutRelationshipConstraints( function() {
				return invoke( relationQuery.getEntity(), listFirst( relationshipName, "." ) );
			} );

		if ( listLen( arguments.relationshipName, "." ) == 1 ) {
			var q = relation
				.addCompareConstraints()
				.when( !isNull( callback ), function( q ) {
					callback( q );
				} )
				.when( !isNull( arguments.operator ) && !isNull( arguments.count ), function( q ) {
					q.having( q.raw( "COUNT(*)" ), operator, count );
				} );

			if ( structKeyExists( q, "retrieveQuery" ) ) {
				q = q.retrieveQuery();
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

		arguments.relationQuery = invoke(
			arguments.relationQuery,
			"whereExists",
			{ "query" : q }
		);

		return whereHasNested( argumentCollection = arguments );
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
	 * @return            quick.models.QuickBuilder
	 */
	public QuickBuilder function orWhereHas(
		required string relationshipName,
		any callback,
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
	 * @return            quick.models.QuickBuilder
	 */
	public QuickBuilder function orWhereDoesntHave(
		required string relationshipName,
		any callback,
		any operator,
		any count
	) {
		arguments.combinator = "or";
		return whereDoesntHave( argumentCollection = arguments );
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
				q = getEntity().withoutRelationshipConstraints( function() {
					return invoke( getEntity(), thisRelationshipName ).addCompareConstraints();
				} );
			} else {
				var relationship = q.withoutRelationshipConstraints( function() {
					return invoke( q, thisRelationshipName );
				} );
				q = relationship.whereExists(
					relationship.addCompareConstraints( q.select( q.raw( 1 ) ) ).retrieveQuery()
				);
			}
			arguments.relationshipName = listRest( arguments.relationshipName, "." );
		}

		return orderBy( q.select( arguments.columnName ).retrieveQuery(), arguments.direction );
	}

	/**
	 * Adds a single order by clause to the query.
	 * Overloaded to proxy to `orderByRelated` when a relationship is found.
	 *
	 * @column     The name of the column(s) to order by.
	 * @direction  The direction by which to order the query.  Accepts "asc" OR "desc". Default: "asc".
	 *
	 * @return     quick.models.QuickBuilder
	 */
	private QuickBuilder function orderBySingle( required any column, string direction = "asc" ) {
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

		return orderByRelated(
			listSlice( arguments.column, 1, -1, "." ),
			listLast( arguments.column, "." ),
			arguments.direction
		);
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
		return getEntity().addSubselect( argumentCollection = arguments );
	}

	/**
	 * Creates a new query using the same Grammar and QueryUtils.
	 *
	 * @return quick.models.QuickBuilder
	 */
	public QuickBuilder function newQuery() {
		var builder = new quick.models.QuickBuilder(
			grammar             = getGrammar(),
			utils               = getUtils(),
			returnFormat        = getReturnFormat(),
			paginationCollector = isNull( variables.paginationCollector ) ? javacast( "null", "" ) : variables.paginationCollector,
			columnFormatter     = isNull( getColumnFormatter() ) ? javacast( "null", "" ) : getColumnFormatter(),
			defaultOptions      = getDefaultOptions()
		);
		builder.setEntity( getEntity() );
		builder.setFrom( getEntity().tableName() );
		return builder;
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
			this
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

		return super.onMissingMethod( arguments.missingMethodName, arguments.missingMethodArguments );
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

}
