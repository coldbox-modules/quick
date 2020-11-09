/**
 * Represents a belongsToMany relationship.
 *
 * This is a relationship where the related entity belongs to
 * zero or more of one of the parent entities. The inverse of this
 * relationship is also a `belongsToMany` relationship.
 *
 * For instance, a `Post` may have zero or more `Tag` entities.
 * The inverse is also true. This would be modeled in Quick by adding a
 * method to the `Post` entity that returns a `BelongsToMany` relationship instance.
 *
 * ```
 * function tags() {
 *     returns belongsToMany( "Tag" );
 * }
 * ```
 */
component extends="quick.models.Relationships.BaseRelationship" accessors="true" {

	/**
	 * The pivot table name between relationships.
	 */
	property name="table" type="string";

	/**
	 * The primary keys for the parent entity.
	 */
	property name="parentKeys" type="array";

	/**
	 * The primary keys for the parent entity.
	 * Alias for `parentKeys`
	 */
	property name="foreignKeys" type="array";

	/**
	 * The primary keys for the related entity.
	 */
	property name="relatedKeys" type="array";

	/**
	 * The keys on the pivot `table` that correspond to the `relatedKeys`.
	 */
	property name="relatedPivotKeys" type="array";

	/**
	 * The keys on the pivot `table` that correspond to the `parentKeys`.
	 */
	property name="foreignPivotKeys" type="array";

	/**
	 * The table suffix. Stored in case this is the `applyThroughConstraints` is called.
	 */
	property name="tableSuffix" type="string";

	/**
	 * Used to check for the type of relationship more quickly than using isInstanceOf.
	 */
	this.relationshipClass = "BelongsToMany";

	/**
	 * Creates a BelongsToMany relationship.
	 *
	 * @related             The related entity instance.
	 * @relationName        The WireBox mapping for the related entity.
	 * @relationMethodName  The method name called to retrieve this relationship.
	 * @parent              The parent entity instance for the relationship.
	 * @table               The table name used as the pivot table for the
	 *                      relationship.  A pivot table is a table that stores,
	 *                      at a minimum, the primary key values of each side
	 *                      of the relationship as foreign keys.
	 * @foreignPivotKeys    The keys on the pivot `table` that correspond to the `parentKeys`.
	 * @relatedPivotKeys    The keys on the pivot `table` that correspond to the `relatedKeys`.
	 * @parentKeys          The name of the columns on the `parent` entity that is
	 *                      stored in the `foreignPivotKey` columns on `table`.
	 * @relatedKeys         The name of the columns on the `related` entity that is
	 *                      stored in the `relatedPivotKey` columns on `table`.
	 *
	 * @return              quick.models.Relationships.BelongsToMany
	 */
	public BelongsToMany function init(
		required any related,
		required string relationName,
		required string relationMethodName,
		required any parent,
		required string table,
		required array foreignPivotKeys,
		required array relatedPivotKeys,
		required array parentKeys,
		required array relatedKeys,
		boolean withConstraints = true
	) {
		variables.table            = arguments.table;
		variables.parentKeys       = arguments.parentKeys;
		variables.foreignKeys      = arguments.parentKeys;
		variables.relatedKeys      = arguments.relatedKeys;
		variables.relatedPivotKeys = arguments.relatedPivotKeys;
		variables.foreignPivotKeys = arguments.foreignPivotKeys;
		variables.tablePrefix      = "";

		return super.init(
			related            = arguments.related,
			relationName       = arguments.relationName,
			relationMethodName = arguments.relationMethodName,
			parent             = arguments.parent,
			withConstraints    = arguments.withConstraints
		);
	}

	/**
	 * Returns the result of the relationship.
	 *
	 * @doc_generic  quick.models.BaseEntity
	 * @return       [quick.models.BaseEntity]
	 */
	public array function getResults() {
		return variables.related.get();
	}

	/**
	 * Adds the constraints to the related entity.
	 *
	 * @return  void
	 */
	public void function addConstraints() {
		performJoin();
		addWhereConstraints();
	}

	/**
	 * Adds the constraints for eager loading.
	 *
	 * @entities  The entities being eager loaded.
	 *
	 * @return    void
	 */
	public boolean function addEagerConstraints( required array entities ) {
		var allKeys = getKeys( entities, variables.parentKeys );
		if ( allKeys.isEmpty() ) {
			return false;
		}

		performJoin();
		variables.foreignPivotKeys.each( function( foreignPivotKey ) {
			variables.related.addSelect( listLast( variables.table, " " ) & "." & foreignPivotKey );
			variables.related.appendVirtualAttribute( name = foreignPivotKey, excludeFromMemento = true );
		} );

		variables.related.where( function( q1 ) {
			allKeys.each( function( keys ) {
				q1.orWhere( function( q2 ) {
					arrayZipEach(
						[
							getQualifiedForeignPivotKeyNames(),
							keys
						],
						function( foreignPivotKeyName, keyValue ) {
							q2.where( foreignPivotKeyName, keyValue );
						}
					);
				} );
			} );
		} );
		return true;
	}

	/**
	 * Initializes the relation to the null value for each entity in an array.
	 *
	 * @entities     The entities to initialize the relation.
	 * @relation     The name of the relation to initialize.
	 *
	 * @doc_generic  quick.models.BaseEntity
	 * @return       [quick.models.BaseEntity]
	 */
	public array function initRelation( required array entities, required string relation ) {
		return arguments.entities.map( function( entity ) {
			return arguments.entity.assignRelationship( relation, [] );
		} );
	}

	/**
	 * Matches the array of entity results to an array of entities for a relation.
	 * Any matched records are populated into the matched entity's relation.
	 *
	 * @entities     The entities being eager loaded.
	 * @results      The relationship results.
	 * @relation     The relation name being loaded.
	 *
	 * @doc_generic  quick.models.BaseEntity
	 * @return       [quick.models.BaseEntity]
	 */
	public array function match(
		required array entities,
		required array results,
		required string relation
	) {
		var dictionary = variables.buildDictionary( arguments.results );
		arguments.entities.each( function( entity ) {
			var parentDictionaryKey = variables.parentKeys
				.map( function( parentKey ) {
					return entity.retrieveAttribute( parentKey );
				} )
				.toList();

			if ( structKeyExists( dictionary, parentDictionaryKey ) ) {
				arguments.entity.assignRelationship( relation, dictionary[ parentDictionaryKey ] );
			}
		} );
		return arguments.entities;
	}

	/**
	 * Builds a dictionary mapping the `foreignPivotKey` value to related results.
	 *
	 * @results      The array of entities from retrieving the relationship.
	 *
	 * @doc_generic  any,quick.models.BaseEntity
	 * @return       {any: quick.models.BaseEntity}
	 */
	public struct function buildDictionary( required array results ) {
		return arguments.results.reduce( function( dict, result ) {
			var key = variables.foreignPivotKeys
				.map( function( foreignPivotKey ) {
					return result.retrieveAttribute( foreignPivotKey );
				} )
				.toList();
			if ( !structKeyExists( arguments.dict, key ) ) {
				arguments.dict[ key ] = [];
			}
			arrayAppend( arguments.dict[ key ], arguments.result );
			return arguments.dict;
		}, {} );
	}

	/**
	 * Adds a join to the pivot table for the relationship.
	 *
	 * @return  quick.models.Relationships.BelongsToMany
	 */
	public BelongsToMany function performJoin( any base = variables.related ) {
		arguments.base.join( variables.table, function( j ) {
			arrayZipEach(
				[
					variables.relatedKeys,
					getQualifiedRelatedPivotKeyNames()
				],
				function( relatedKey, pivotKey ) {
					j.on( variables.related.qualifyColumn( relatedKey ), pivotKey );
				}
			);
		} );
		return this;
	}

	/**
	 * Adds the where constraints for the relationship.
	 *
	 * @return  quick.models.Relationships.BelongsToMany
	 */
	public BelongsToMany function addWhereConstraints() {
		variables.related.where( function( q ) {
			arrayZipEach(
				[
					getQualifiedForeignPivotKeyNames(),
					variables.parentKeys
				],
				function( pivotKey, parentKey ) {
					q.where( pivotKey, variables.parent.retrieveAttribute( parentKey ) );
				}
			);
		} );
		return this;
	}

	/**
	 * Get's the qualified related pivot key column name.
	 * Qualified columns are "table.column".
	 *
	 * @doc_generic  String
	 * @return       [String]
	 */
	public array function getQualifiedRelatedPivotKeyNames() {
		return variables.relatedPivotKeys.map( function( relatedPivotKey ) {
			return listLast( variables.table, " " ) & "." & relatedPivotKey;
		} );
	}

	/**
	 * Get's the qualified foreign pivot key column name.
	 * Qualified columns are "table.column".
	 *
	 * @doc_generic  String
	 * @return       [String]
	 */
	public array function getQualifiedForeignPivotKeyNames() {
		return variables.foreignPivotKeys.map( function( foreignPivotKey ) {
			return listLast( variables.table, " " ) & "." & foreignPivotKey;
		} );
	}

	/**
	 * Associates one or more ids of the related entity to the parent entity.
	 *
	 * @id      The id or array of ids of the related entity.
	 *
	 * @return  quick.models.BaseEntity
	 */
	public any function attach( required any id ) {
		variables.newPivotStatement().insert( parseIdsForInsert( arguments.id ) );
		return variables.parent;
	}

	/**
	 * Deletes one or more ids of the related entity from the pivot table
	 * where the foreign key is the parent's foreign key value..
	 *
	 * @id      The id or array of ids of the related entity to delete.
	 *
	 * @return  quick.models.BaseEntity
	 */
	public any function detach( required any id ) {
		var foreignPivotKeyValues = variables.parentKeys.map( function( parentKey ) {
			return variables.parent.retrieveAttribute( parentKey );
		} );
		variables
			.newPivotStatement()
			.where( function( q ) {
				arrayZipEach(
					[
						variables.foreignPivotKeys,
						foreignPivotKeyValues
					],
					function( foreignPivotKey, foreignPivotKeyValue ) {
						q.where( foreignPivotKey, foreignPivotKeyValue );
					}
				);
			} )
			.where( function( q1 ) {
				parseIds( arrayWrap( id ) ).each( function( ids ) {
					q1.orWhere( function( q2 ) {
						arrayZipEach( [ variables.relatedPivotKeys, ids ], function( relatedPivotKey, id ) {
							q2.where( relatedPivotKey, id );
						} );
					} );
				} );
			} )
			.delete();
		return variables.parent;
	}

	/**
	 * Associates the given entity when the relationship is used as a setter.
	 *
	 * Relationships on entities can be called with `set` in front of it.
	 * If it is, a `BelongsTo` relationship forwards the call to `associate`.
	 *
	 * @id      The entity or entity id to associate as the new owner.
	 *          If an entity is passed, it is also cached in the child entity
	 *          as the value for the relationship.
	 *
	 * @return  quick.models.BaseEntity
	 */
	function applySetter() {
		return sync( argumentCollection = arguments );
	}

	/**
	 * Uses the ids provided as the only relationships between the parent and
	 * related entity. It deletes all current ids in the pivot table for the
	 * parent and then attaches all the provided related ids to the parent.
	 *
	 * @id      The id or array of ids that should be the only relationships
	 *          between the parent and related entities.
	 *
	 * @return  quick.models.BaseEntity
	 */
	public any function sync( required any id ) {
		var foreignPivotKeyValues = variables.parentKeys.map( function( parentKey ) {
			return variables.parent.retrieveAttribute( parentKey );
		} );
		variables
			.newPivotStatement()
			.where( function( q ) {
				arrayZipEach(
					[
						variables.foreignPivotKeys,
						foreignPivotKeyValues
					],
					function( foreignPivotKey, foreignPivotKeyValue ) {
						q.where( foreignPivotKey, foreignPivotKeyValue );
					}
				);
			} )
			.delete();
		return variables.attach( arguments.id );
	}

	/**
	 * Returns a new query based on the pivot table.
	 *
	 * @return  qb.models.Query.QueryBuilder
	 */
	public any function newPivotStatement() {
		return variables.related.set_table( variables.table ).newQuery();
	}

	/**
	 * Normalizes a single id or entity or an array of ids and/or entities
	 * in to an array of ids.
	 *
	 * @value        An id, entity, or combination of either in an array.
	 *
	 * @doc_generic  any
	 * @return       [any]
	 */
	public array function parseIds( required any value ) {
		return arrayWrap( arguments.value ).map( function( val ) {
			// If the value is not a simple value, we will assume
			// it is an entity and return its key value.
			if ( isObject( arguments.val ) ) {
				return arguments.val.keyValues();
			}
			return arrayWrap( arguments.val );
		} );
	}

	/**
	 * Normalizes a single id or entity or an array of ids and/or entities
	 * in to an array of struct pairs for insert into the pivot table.
	 *
	 * @value        An id, entity, or combination of either in an array.
	 *
	 * @doc_generic  any,any
	 * @return       [{any: any}]
	 */
	public array function parseIdsForInsert( required any value ) {
		var foreignPivotKeyValues = variables.parentKeys.map( function( parentKey ) {
			return variables.parent.retrieveAttribute( parentKey );
		} );
		return arrayWrap( arguments.value ).map( function( values ) {
			// If the value is not a simple value, we will assume
			// it is an entity and return its key value.
			if ( isObject( arguments.values ) ) {
				arguments.values = arguments.values.keyValues();
			} else {
				arguments.values = arrayWrap( arguments.values );
			}
			var insertRecord = {};
			arrayZipEach(
				[
					variables.foreignPivotKeys,
					foreignPivotKeyValues,
					variables.relatedPivotKeys,
					arguments.values
				],
				function(
					foreignPivotKey,
					foreignPivotKeyValue,
					relatedPivotKey,
					val
				) {
					insertRecord[ foreignPivotKey ] = foreignPivotKeyValue;
					insertRecord[ relatedPivotKey ] = val;
				}
			);
			return insertRecord;
		} );
	}

	/**
	 * Gets the query used to check for relation existance.
	 *
	 * @base    The base entity for the query.
	 *
	 * @return  qb.models.Query.QueryBuilder
	 */
	public any function addCompareConstraints( any base = variables.related.newQuery(), any nested ) {
		if ( !isNull( arguments.nested ) ) {
			return addNestedCompareConstraints( arguments.base, arguments.nested );
		}

		return arguments.base
			.newQuery()
			.select( variables.parent.raw( 1 ) )
			.from( variables.table )
			.where( function( q ) {
				arrayZipEach(
					[
						getQualifiedForeignKeyNames(),
						variables.parent.retrieveQualifiedKeyNames()
					],
					function( foreignKeyName, keyName ) {
						q.whereColumn( foreignKeyName, keyName );
					}
				);
			} );
	}

	public any function addNestedCompareConstraints( required any base, required any nested ) {
		return arguments.base
			.select( variables.related.raw( 1 ) )
			.whereExists( function( q ) {
				q.selectRaw( 1 ).from( variables.table );
				arrayZipEach(
					[
						getQualifiedRelatedPivotKeyNames(),
						variables.related.retrieveQualifiedKeyNames()
					],
					function( relatedPivotKeyName, keyName ) {
						q.whereColumn( relatedPivotKeyName, keyName );
					}
				);

				var nestedQuery = isBoolean( nested ) ? q : nested.clone().select( variables.parent.raw( 1 ) );
				arrayZipEach(
					[
						getQualifiedForeignKeyNames(),
						variables.parent.retrieveQualifiedKeyNames()
					],
					function( foreignKeyName, keyName ) {
						nestedQuery.whereColumn( foreignKeyName, keyName );
					}
				);

				if ( isBoolean( nested ) ) {
					return;
				}

				if ( structKeyExists( nestedQuery, "retrieveQuery" ) ) {
					nestedQuery = nestedQuery.retrieveQuery();
				}

				q.whereExists( nestedQuery );
			} );
	}

	function nestCompareConstraints( base, nested ) {
		return structKeyExists( arguments.nested, "retrieveQuery" ) ? arguments.nested.retrieveQuery() : arguments.nested;
	}

	/**
	 * Returns the fully-qualified column name of foreign key.
	 *
	 * @doc_generic  String
	 * @return       [String]
	 */
	public array function getQualifiedForeignKeyNames() {
		return getQualifiedForeignPivotKeyNames();
	}

	/**
	 * Applies a suffix to an alias for the relationship.
	 * This is ignored for `hasManyThrough` because each of the relationship
	 * components inside `relationshipsMap` will already be aliased.
	 *
	 * @suffix   The suffix to use.
	 *
	 * @return  quick.models.Relationships.HasManyThrough
	 */
	public BelongsToMany function applyAliasSuffix( required string suffix ) {
		variables.tableSuffix = arguments.suffix;
		variables.table       = "#variables.table# #variables.table##suffix#";
		super.applyAliasSuffix( argumentCollection = arguments );
		return this;
	}

	public QuickBuilder function initialThroughConstraints() {
		var base = variables.related
			.newQuery()
			.reselectRaw( 1 )
			.from( variables.table );

		arrayZipEach(
			[
				variables.relatedKeys,
				getQualifiedRelatedPivotKeyNames()
			],
			function( relatedKey, pivotKey ) {
				base.whereColumn( variables.related.qualifyColumn( relatedKey ), pivotKey );
			}
		);

		return variables.related
			.newQuery()
			.reselectRaw( 1 )
			.whereExists( base );
	}

	/**
	 * Applies the exists for relationship in a `hasManyThrough` chain.
	 *
	 * @base    The query to apply the exists to.
	 *
	 * @return  void
	 */
	public QuickBuilder function applyThroughExists( required QuickBuilder base ) {
		// apply compare constraints for pivot table
		arrayZipEach(
			[
				variables.foreignKeys,
				getQualifiedForeignPivotKeyNames()
			],
			function( foreignKey, pivotKey ) {
				base.whereColumn( variables.parent.qualifyColumn( foreignKey ), pivotKey );
			}
		);

		// nest in where exists for pivot table
		arguments.base = variables.parent
			.newQuery()
			.reselectRaw( 1 )
			.from( variables.table )
			.whereExists( arguments.base );

		// apply compare constraints for base table
		arrayZipEach(
			[
				variables.relatedKeys,
				getQualifiedRelatedPivotKeyNames()
			],
			function( relatedKey, pivotKey ) {
				base.whereColumn( variables.related.qualifyColumn( relatedKey ), pivotKey );
			}
		);

		// nest in where exists for base table
		return variables.related
			.newQuery()
			.reselectRaw( 1 )
			.whereExists( arguments.base );
	}

	/**
	 * Applies the join for relationship in a `hasManyThrough` chain.
	 *
	 * @base    The query to apply the join to.
	 *
	 * @return  void
	 */
	public void function applyThroughJoin( required any base ) {
		performJoin( arguments.base );
		arguments.base.join( variables.parent.tableName(), function( j ) {
			arrayZipEach(
				[
					variables.parentKeys,
					getQualifiedForeignPivotKeyNames()
				],
				function( parentKey, pivotKey ) {
					j.on( variables.parent.qualifyColumn( parentKey ), pivotKey );
				}
			);
		} );
	}

	/**
	 * Applies the constraints for the final relationship in a `hasManyThrough` chain.
	 *
	 * @base    The query to apply the constraints to.
	 *
	 * @return  void
	 */
	public void function applyThroughConstraints( required any base ) {
		variables.parent.withAlias( variables.parent.tableName() & variables.tableSuffix );
		performJoin( arguments.base );
		arguments.base.where( function( q ) {
			arrayZipEach(
				[
					getQualifiedForeignPivotKeyNames(),
					variables.parentKeys
				],
				function( localKey, parentKey ) {
					q.where(
						variables.related.qualifyColumn( localKey ),
						variables.parent.retrieveAttribute( parentKey )
					);
				}
			);
		} );
	}

}
