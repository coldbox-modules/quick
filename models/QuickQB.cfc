/**
 *  QueryBuilder super-type to add additional Quick-only features like relationship querying and ordering to qb queries.
 */
component
	extends       ="qb.models.Query.QueryBuilder"
	accessors     ="true"
	transientCache="false"
{

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
	 * Adds a WHERE IN clause to the query using a subselect.  To call this using the public api, pass a closure to `whereIn` as the second argument (`values`).
	 *
	 * @column The name of the column with which to constrain the query.
	 * @callback A closure that will contain the subquery with which to constain this clause.
	 * @combinator The boolean combinator for the clause (e.g. "and" or "or"). Default: "and"
	 * @negate False for IN, True for NOT IN. Default: false.
	 *
	 * @return qb.models.Query.QueryBuilder
	 */
	private QuickQB function whereInSub(
		column,
		query,
		combinator = "and",
		negate     = false
	) {
		if ( isStruct( arguments.query ) && structKeyExists( arguments.query, "isQuickBuilder" ) ) {
			arguments.query = arguments.query.getQB();
		}

		return super.whereInSub( argumentCollection = arguments );
	}

	/**
	 * Sets the FROM table of the query using a derived table.
	 *
	 * @alias The alias for the derived table
	 * @input Either a QueryBuilder instance or a closure to define the derived query.
	 *
	 * @return qb.models.Query.QueryBuilder
	 */
	public QuickQB function fromSub( required string alias, required any input ) {
		if ( structKeyExists( arguments.input, "isQuickBuilder" ) ) {
			arguments.input = arguments.input.getQB();
		}

		return super.fromSub( argumentCollection = arguments );
	}

	/**
	 * Adds an INNER JOIN from a derived table to another table.
	 *
	 * For simple joins, this specifies a column on which to join the two tables.
	 * For complex joins, a closure can be passed to `first`.
	 * This allows multiple `on` and `where` conditions to be applied to the join.
	 *
	 * @alias The alias for the derived table
	 * @input Either a QueryBuilder instance or a closure to define the derived query.
	 * @first The first column in the join's `on` statement. This alternatively can be a closure that will be passed a JoinClause for complex joins. Passing a closure ignores all subsequent parameters.
	 * @operator The boolean operator for the join clause. Default: "=".
	 * @second The second column in the join's `on` statement.
	 * @type The type of the join. Default: "inner".  Passing this as an argument is discouraged for readability.  Use the dedicated methods like `leftJoin` and `rightJoin` where possible.
	 * @where Sets if the value of `second` should be interpreted as a column or a value.  Passing this as an argument is discouraged.  Use the dedicated `joinWhere` or a join closure where possible.
	 *
	 * @return qb.models.Query.QueryBuilder
	 */
	public QuickQB function joinSub(
		required string alias,
		required any input,
		required any first,
		string operator = "=",
		string second,
		string type   = "inner",
		boolean where = false
	) {
		if ( structKeyExists( arguments.input, "isQuickBuilder" ) ) {
			arguments.input = arguments.input.getQB();
		}

		return super.joinSub( argumentCollection = arguments );
	}

	/**
	 * Adds a where clause where the value is a subquery.
	 *
	 * @column The name of the column with which to constrain the query.
	 * @operator The operator to use for the constraint (i.e. "=", "<", ">=", etc.).
	 * @callback The closure that defines the subquery. A new query will be passed to the closure as the only argument.
	 * @combinator The boolean combinator for the clause (e.g. "and" or "or"). Default: "and"
	 *
	 * @return qb.models.Query.QueryBuilder
	 */
	private QuickQB function whereSub(
		column,
		operator,
		query,
		combinator = "and"
	) {
		if ( structKeyExists( arguments.query, "isQuickBuilder" ) ) {
			arguments.query = arguments.query.getQB();
		}

		return super.whereSub( argumentCollection = arguments );
	}

	/**
	 * Add an order by clause with a subquery to the query.
	 *
	 * @query     The builder instance or closure to define the query.
	 * @direction The direction by which to order the query.  Accepts "asc" OR "desc". Default: "asc".
	 *
	 * @return    qb.models.Query.QueryBuilder
	 */
	public QuickQB function orderBySub( required any query, string direction = "asc" ) {
		if ( structKeyExists( arguments.query, "isQuickBuilder" ) ) {
			arguments.query = arguments.query.getQB();
		}

		return super.orderBySub( argumentCollection = arguments );
	}

	/**
	 * Adds a CROSS JOIN from a derived table to another table.
	 *
	 * For simple joins, this joins one table to another in a cross join.
	 * For complex joins, a closure can be passed to `first`.
	 * This allows multiple `on` and `where` conditions to be applied to the join.
	 *
	 * @alias The alias for the derived table
	 * @input Either a QueryBuilder instance or a closure to define the derived query.
	 *
	 * @return qb.models.Query.QueryBuilder
	 */
	public QuickQB function crossJoinSub( required any alias, required any input ) {
		if ( structKeyExists( arguments.input, "isQuickBuilder" ) ) {
			arguments.input = arguments.input.getQB();
		}

		return super.crossJoinSub( argumentCollection = arguments );
	}

	/**
	 * Adds a WHERE NULL clause with a subselect to the query.
	 *
	 * @query The builder instance or closure to apply.
	 * @combinator The boolean combinator for the clause (e.g. "and" or "or"). Default: "and"
	 * @negate False for NULL, True for NOT NULL. Default: false.
	 *
	 * @return qb.models.Query.QueryBuilder
	 */
	public QuickQB function whereNullSub(
		query,
		combinator = "and",
		negate     = false
	) {
		if ( structKeyExists( arguments.query, "isQuickBuilder" ) ) {
			arguments.query = arguments.query.getQB();
		}

		return super.whereNullSub( argumentCollection = arguments );
	}

	/**
	 * Adds a WHERE BETWEEN clause to the query.
	 *
	 * @column The name of the column with which to constrain the query.
	 * @start The beginning value of the BETWEEN statement.
	 * @end The end value of the BETWEEN statement.
	 * @combinator The boolean combinator for the clause (e.g. "and" or "or"). Default: "and"
	 * @negate False for BETWEEN, True for NOT BETWEEN. Default: false.
	 *
	 * @return qb.models.Query.QueryBuilder
	 */
	public QueryBuilder function whereBetween(
		column,
		start,
		end,
		combinator = "and",
		negate     = false
	) {
		if ( !isSimpleValue( arguments.start ) && structKeyExists( arguments.start, "isQuickBuilder" ) ) {
			arguments.start = arguments.start.getQB();
		}

		if ( !isSimpleValue( arguments.end ) && structKeyExists( arguments.end, "isQuickBuilder" ) ) {
			arguments.end = arguments.end.getQB();
		}

		return super.whereBetween( argumentCollection = arguments );
	}

	/**
	 * Add a UNION statement to the SQL.
	 *
	 * @input   Either a QueryBuilder instance or a closure to define the derived query.
	 * @all     Determines if UNION statement should be a "UNION ALL".  Passing this as an argument is discouraged.  Use the dedicated `unionAll` where possible.
	 *
	 * @return  qb.models.Query.QueryBuilder
	 */
	public QueryBuilder function union( required any input, boolean all = false ) {
		if ( structKeyExists( arguments.input, "isQuickBuilder" ) ) {
			arguments.input = arguments.input.getQB();
		}

		return super.union( argumentCollection = arguments );
	}

	/**
	 * Adds a new COMMON TABLE EXPRESSION (CTE) to the SQL.
	 *
	 * @name        The name of the CTE.
	 * @input       Either a QueryBuilder instance or a closure to define the derived query.
	 * @columns     An optional array containing the columns to include in the CTE.
	 * @recursive   Determines if CTE statement should be a recursive CTE.  Passing this as an argument is discouraged.  Use the dedicated `withRecursive` where possible.
	 *
	 * @return qb.models.Query.QueryBuilder
	 */
	public QueryBuilder function with(
		required string name,
		required any input,
		array columns     = [],
		boolean recursive = false
	) {
		if ( structKeyExists( arguments.input, "isQuickBuilder" ) ) {
			arguments.input = arguments.input.getQB();
		}

		return super.with( argumentCollection = arguments );
	}

	/**
	 * Inserts data into a table based off of a query.
	 * This call must come after setting the query's table using `from` or `table`.
	 *
	 * @source A callback function or QueryBuilder object to insert records from.
	 * @columns An array of columns to insert. If no columns are passed, the columns will be derived from the source columns and aliases.
	 * @options Any options to pass to `queryExecute`. Default: {}.
	 * @toSql If true, returns the raw sql string instead of running the query.  Useful for debugging. Default: false.
	 *
	 * @return query
	 */
	public any function insertUsing(
		required any source,
		array columns,
		struct options = {},
		boolean toSql  = false
	) {
		if ( structKeyExists( arguments.source, "isQuickBuilder" ) ) {
			arguments.source = arguments.source.getQB();
		}

		return super.insertUsing( argumentCollection = arguments );
	}

	/**
	 * Updates a table with a struct of column and value pairs.
	 * This call must come after setting the query's table using `from` or `table`.
	 * Any constraining of the update query should be done using the appropriate WHERE statement before calling `update`.
	 *
	 * @values A struct of column and value pairs to update.
	 * @options Any options to pass to `queryExecute`. Default: {}.
	 * @toSql If true, returns the raw sql string instead of running the query.  Useful for debugging. Default: false.
	 *
	 * @return query
	 */
	public any function update(
		struct values  = {},
		struct options = {},
		boolean toSql  = false
	) {
		for ( var key in arguments.values ) {
			if ( structKeyExists( arguments.values[ key ], "isQuickBuilder" ) ) {
				arguments.values[ key ] = arguments.values[ key ].getQb();
			}
		}

		return super.update( argumentCollection = arguments );
	}

	public any function upsert(
		required any values,
		required any target,
		any update,
		any source,
		boolean deleteUnmatched = false,
		struct options          = {},
		boolean toSql           = false
	) {
		if ( !isNull( arguments.source ) && structKeyExists( arguments.source, "isQuickBuilder" ) ) {
			arguments.source = arguments.source.getQB();
		}

		return super.upsert( argumentCollection = arguments );
	}

	/**
	 * Adds a sub-select to the query.
	 *
	 * @alias The alias for the sub-select
	 * @callback The callback or query to configure the sub-select.
	 *
	 * @returns qb.models.Query.QueryBuilder
	 */
	public QueryBuilder function subSelect( required string alias, required any query ) {
		if ( structKeyExists( arguments.query, "isQuickBuilder" ) ) {
			arguments.query = arguments.query.getQB();
		}

		return super.subSelect( argumentCollection = arguments );
	}

	/**
	 * Adds a WHERE EXISTS clause to the query.
	 *
	 * @callback A callback to specify the query for the EXISTS clause.  It will be passed a query as the only argument.
	 * @combinator The boolean combinator for the clause (e.g. "and" or "or"). Default: "and"
	 * @negate False for EXISTS, True for NOT EXISTS. Default: false.
	 *
	 * @return qb.models.Query.QueryBuilder
	 */
	public QueryBuilder function whereExists(
		query,
		combinator = "and",
		negate     = false
	) {
		if (
			!isClosure( arguments.query ) && !isCustomFunction( arguments.query ) && structKeyExists(
				arguments.query,
				"isQuickBuilder"
			)
		) {
			arguments.query = arguments.query.getQB();
		}

		return super.whereExists( argumentCollection = arguments );
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
			var relationName = listFirst( relationshipName, "." );
			return getEntity().withoutRelationshipConstraints( relationName, function() {
				return invoke( getEntity(), relationName );
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
				var relationName = listFirst( relationshipName, "." );
				return relationQuery
					.getEntity()
					.withoutRelationshipConstraints( relationName, function() {
						return invoke( relationQuery.getEntity(), relationName );
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
			var relationName = listFirst( relationshipName, "." );
			return getEntity().withoutRelationshipConstraints( relationName, function() {
				return invoke( getEntity(), relationName );
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
				var relationName = listFirst( relationshipName, "." );
				return relationQuery
					.getEntity()
					.withoutRelationshipConstraints( relationName, function() {
						return invoke( relationQuery.getEntity(), relationName );
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
		if ( !isNull( arguments.value ) && getUtils().isValidQueryParamStruct( arguments.value ) ) {
			return arguments.value;
		}

		if ( arguments.checkNullValues ) {
			return {
				"value" : ( isNull( arguments.value ) || getEntity().isNullValue( arguments.column, arguments.value ) ) ? "" : getEntity().convertToCastedValue(
					arguments.column,
					arguments.value
				),
				"cfsqltype" : getEntity().attributeHasSqlType( arguments.column ) ? getEntity().retrieveSqlTypeForAttribute(
					arguments.column
				) : (
					isNull( arguments.value ) ? "CF_SQL_VARCHAR" : getUtils().inferSqlType(
						getEntity().convertToCastedValue( arguments.column, arguments.value ),
						variables.grammar
					)
				),
				"null" : isNull( arguments.value ) || (
					getEntity().canConvertToNull( arguments.column ) && getEntity().isNullValue(
						arguments.column,
						arguments.value
					)
				),
				"nulls" : isNull( arguments.value ) || (
					getEntity().canConvertToNull( arguments.column ) && getEntity().isNullValue(
						arguments.column,
						arguments.value
					)
				)
			};
		} else {
			return {
				"value" : isNull( arguments.value ) ? "" : getEntity().convertToCastedValue(
					arguments.column,
					arguments.value
				),
				"cfsqltype" : getEntity().attributeHasSqlType( arguments.column ) ? getEntity().retrieveSqlTypeForAttribute(
					arguments.column
				) : (
					isNull( arguments.value ) ? "CF_SQL_VARCHAR" : getUtils().inferSqlType(
						getEntity().convertToCastedValue( arguments.column, arguments.value ),
						variables.grammar
					)
				),
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
			parentQuery         = isNull( getParentQuery() ) ? javacast( "null", "" ) : getParentQuery().clone(),
			defaultOptions      = getDefaultOptions()
		);
		newBuilder.setQuickBuilder( getQuickBuilder() );
		newBuilder.setEntity( getEntity() );
		newBuilder.setTableName( getTableName() );
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

		// common with super
		var query = forNestedWhere();

		// unique to this
		var saved_QB = this.getQuickBuilder().getQB();
		this.getQuickBuilder().setQB( query );

		// common with super
		callback( query );

		// unique to this
		this.getQuickBuilder().setQB( saved_QB );

		// common with super
		return addNestedWhereQuery( query, combinator );
	}

}
