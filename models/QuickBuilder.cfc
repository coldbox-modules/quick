component extends="qb.models.Query.QueryBuilder" accessors="true" {

    /**
     * The entity associated with this builder.
     */
    property name="entity";

    /**
     * Checks for the existence of a relationship when executing the query.
     *
     * @relationshipName  The relationship to check.
     * @operator          An optional operator to constrain the check.
     * @count             An optional count to constrain the check.
     *
     * @return            quick.models.BaseEntity
     */
    public any function has(
        required string relationshipName,
        string operator,
        numeric count,
        boolean negate = false
    ) {
        var methodName = arguments.negate ? "whereNotExists" : "whereExists";
        var relation = invoke(
            getEntity(),
            listFirst( arguments.relationshipName, "." )
        );
        arguments.relationQuery = relation.getRelationExistenceQuery(
            relation.getRelated()
        );

        if ( listLen( arguments.relationshipName, "." ) > 1 ) {
            arguments.relationshipName = listRest(
                arguments.relationshipName,
                "."
            );

            invoke(
                this,
                methodName,
                { "query": hasNested( argumentCollection = arguments ) }
            );

            return this;
        }

        invoke(
            this,
            methodName,
            {
                "query": arguments.relationQuery.when( !isNull( arguments.operator ) && !isNull( arguments.count ), function( q ) {
                    q.having( q.raw( "COUNT(*)" ), operator, count );
                } )
            }
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
     * @return            quick.models.BaseEntity
     */
    public any function doesntHave(
        required string relationshipName,
        string operator,
        numeric count
    ) {
        arguments.negate = true;
        return has( argumentCollection = arguments );
    }

    private any function hasNested(
        required any relationQuery,
        required string relationshipName,
        string operator,
        numeric count
    ) {
        var relation = invoke(
            arguments.relationQuery.getEntity(),
            listFirst( arguments.relationshipName, "." )
        );

        if ( listLen( arguments.relationshipName, "." ) == 1 ) {
            return invoke(
                arguments.relationQuery,
                "whereExists",
                {
                    "query": relation
                        .getRelationExistenceQuery( relation.getRelated() )
                        .when(
                            !isNull( arguments.operator ) && !isNull(
                                arguments.count
                            ),
                            function( q ) {
                                q.having( q.raw( "COUNT(*)" ), operator, count );
                            }
                        )
                }
            );
        }

        arguments.relationQuery = invoke(
            arguments.relationQuery,
            "whereExists",
            {
                "query": relation.getRelationExistenceQuery(
                    relation.getRelated()
                )
            }
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
     * @return            quick.models.BaseEntity
     */
    public any function whereHas(
        required string relationshipName,
        any callback,
        any operator,
        any count,
        string combinator = "and",
        boolean negate = false
    ) {
        var methodName = arguments.negate ? "whereNotExists" : "whereExists";
        var relation = invoke(
            getEntity(),
            listFirst( arguments.relationshipName, "." )
        );
        arguments.relationQuery = relation.getRelationExistenceQuery(
            relation.getRelated()
        );

        if ( listLen( arguments.relationshipName, "." ) > 1 ) {
            arguments.relationshipName = listRest(
                arguments.relationshipName,
                "."
            );

            invoke(
                this,
                methodName,
                { "query": whereHasNested( argumentCollection = arguments ) }
            );

            return this;
        }

        invoke(
            this,
            methodName,
            {
                "query": arguments.relationQuery
                    .when( !isNull( callback ), function( q ) {
                        callback( q );
                    } )
                    .when(
                        !isNull( arguments.operator ) && !isNull(
                            arguments.count
                        ),
                        function( q ) {
                            q.having( q.raw( "COUNT(*)" ), operator, count );
                        }
                    ),
                "combinator": arguments.combinator
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
     * @return            quick.models.BaseEntity
     */
    public any function whereDoesntHave(
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
     * @return            qb.models.Query.QueryBuilder
     */
    private any function whereHasNested(
        required any relationQuery,
        required string relationshipName,
        any callback,
        string operator,
        numeric count
    ) {
        var relation = invoke(
            arguments.relationQuery.getEntity(),
            listFirst( arguments.relationshipName, "." )
        );

        if ( listLen( arguments.relationshipName, "." ) == 1 ) {
            return invoke(
                arguments.relationQuery,
                "whereExists",
                {
                    "query": relation
                        .getRelationExistenceQuery( relation.getRelated() )
                        .when( !isNull( callback ), function( q ) {
                            callback( q );
                        } )
                        .when(
                            !isNull( arguments.operator ) && !isNull(
                                arguments.count
                            ),
                            function( q ) {
                                q.having( q.raw( "COUNT(*)" ), operator, count );
                            }
                        )
                }
            );
        }

        arguments.relationQuery = invoke(
            arguments.relationQuery,
            "whereExists",
            {
                "query": relation.getRelationExistenceQuery(
                    relation.getRelated()
                )
            }
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
     * @return            quick.models.BaseEntity
     */
    public any function orWhereHas(
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
     * @return            quick.models.BaseEntity
     */
    public any function orWhereDoesntHave(
        required string relationshipName,
        any callback,
        any operator,
        any count
    ) {
        arguments.combinator = "or";
        return whereDoesntHave( argumentCollection = arguments );
    }

    /**
     * Creates a new query using the same Grammar and QueryUtils.
     *
     * @return quick.models.QuickBuilder
     */
    public QuickBuilder function newQuery() {
        var builder = new quick.models.QuickBuilder(
            grammar = getGrammar(),
            utils = getUtils(),
            returnFormat = getReturnFormat(),
            paginationCollector = isNull( variables.paginationCollector ) ? javacast(
                "null",
                ""
            ) : variables.paginationCollector,
            columnFormatter = isNull( getColumnFormatter() ) ? javacast(
                "null",
                ""
            ) : getColumnFormatter(),
            defaultOptions = getDefaultOptions()
        );
        builder.setEntity( getEntity() );
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
    public any function onMissingMethod(
        required string missingMethodName,
        struct missingMethodArguments = {}
    ) {
        var q = getEntity().tryScopes(
            arguments.missingMethodName,
            arguments.missingMethodArguments
        );
        if ( !isNull( q ) ) {
            // If a query is returned, set it as the current query and return
            // the entity. Otherwise return whatever came back from the scope.
            if ( isStruct( q ) && structKeyExists( q, "retrieveQuery" ) ) {
                return this;
            }
            return q;
        }

        return super.onMissingMethod(
            arguments.missingMethodName,
            arguments.missingMethodArguments
        );
    }

}
