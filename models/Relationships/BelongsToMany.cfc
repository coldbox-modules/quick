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
component
	extends   ="quick.models.Relationships.BaseRelationship"
	implements="IConcatenatableRelationship"
	accessors ="true"
{

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
	 * Additional pivot columns to hydrate on the pivot model.
	 */
	property name="pivotColumns" type="array";

	/**
	 * The relationship name used to expose the hydrated pivot model.
	 */
	property name="pivotAccessor" type="string";

	/**
	 * An optional custom Pivot entity mapping.
	 */
	property name="pivotEntity";

	/**
	 * Internal aliases used to keep pivot columns separate from related columns.
	 */
	property name="pivotColumnAliases" type="struct";

	/**
	 * Values applied to pivot writes and relationship constraints.
	 */
	property name="pivotValues" type="struct";

	/**
	 * Configured created and modified timestamp columns for pivot writes.
	 */
	property name="pivotTimestampColumns" type="array";

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
		variables.table                 = arguments.table;
		variables.parentKeys            = arguments.parentKeys;
		variables.foreignKeys           = arguments.parentKeys;
		variables.relatedKeys           = arguments.relatedKeys;
		variables.relatedPivotKeys      = arguments.relatedPivotKeys;
		variables.foreignPivotKeys      = arguments.foreignPivotKeys;
		variables.tablePrefix           = "";
		variables.pivotColumns          = [];
		variables.pivotAccessor         = "pivot";
		variables.pivotColumnAliases    = {};
		variables.pivotValues           = {};
		variables.pivotTimestampColumns = [];
		variables.pivotEntity           = "";

		super.init(
			related            = arguments.related,
			relationName       = arguments.relationName,
			relationMethodName = arguments.relationMethodName,
			parent             = arguments.parent,
			withConstraints    = arguments.withConstraints
		);

		variables.relationshipBuilder.addEntityTransformer( function( entity ) {
			return hydratePivot( arguments.entity );
		} );

		return this;
	}

	/**
	 * Returns the result of the relationship.
	 *
	 * @doc_generic  quick.models.BaseEntity
	 * @return       [quick.models.BaseEntity]
	 */
	public array function getResults() {
		return variables.relationshipBuilder.get();
	}

	/**
	 * Adds the constraints to the related entity.
	 *
	 * @return  void
	 */
	public void function addConstraints() {
		performJoin();
		addPivotSelects();
		addWhereConstraints();
	}

	/**
	 * Adds the constraints for eager loading.
	 *
	 * @entities  The entities being eager loaded.
	 *
	 * @return    void
	 */
	public boolean function addEagerConstraints( required array entities, required any baseEntity ) {
		var allKeys = getKeys(
			entities,
			variables.parentKeys,
			arguments.baseEntity
		);
		if ( allKeys.isEmpty() ) {
			return false;
		}

		performJoin();
		addPivotSelects();

		var eagerConstraints   = variables.relationshipBuilder.getQB().forNestedWhere();
		var qualifiedPivotKeys = getQualifiedForeignPivotKeyNames();
		for ( var keys in allKeys ) {
			var keyConstraints = eagerConstraints.forNestedWhere();
			for ( var i = 1; i <= qualifiedPivotKeys.len(); i++ ) {
				keyConstraints.where( qualifiedPivotKeys[ i ], keys[ i ] );
			}
			eagerConstraints.addNestedWhereQuery( keyConstraints, "or" );
		}
		variables.relationshipBuilder.getQB().addNestedWhereQuery( eagerConstraints );
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
			if ( structKeyExists( arguments.entity, "isQuickEntity" ) ) {
				arguments.entity.assignRelationship( relation, [] );
			} else {
				arguments.entity[ relation ] = [];
			}
			return arguments.entity;
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
		for ( var entity in arguments.entities ) {
			var parentKeyValues = [];
			for ( var parentKey in variables.parentKeys ) {
				parentKeyValues.append(
					structKeyExists( entity, "isQuickEntity" ) ? entity.retrieveAttribute( parentKey ) : entity[ parentKey ]
				);
			}
			var parentDictionaryKey = parentKeyValues.toList();

			if ( structKeyExists( dictionary, parentDictionaryKey ) ) {
				if ( structKeyExists( entity, "isQuickEntity" ) ) {
					entity.assignRelationship( arguments.relation, dictionary[ parentDictionaryKey ] );
				} else {
					entity[ arguments.relation ] = dictionary[ parentDictionaryKey ];
				}
			}
		}
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
		var dictionary = {};
		for ( var result in arguments.results ) {
			var pivot = structKeyExists( result, "isQuickEntity" )
			 ? result.retrieveRelationship( variables.pivotAccessor )
			 : {};
			var keyValues = [];
			for ( var foreignPivotKey in variables.foreignPivotKeys ) {
				keyValues.append(
					structKeyExists( result, "isQuickEntity" ) ? pivot.retrieveAttribute( foreignPivotKey ) : result[
						variables.pivotColumnAliases[ foreignPivotKey ]
					]
				);
			}
			var key = keyValues.toList();
			if ( !structKeyExists( dictionary, key ) ) {
				dictionary[ key ] = [];
			}
			arrayAppend( dictionary[ key ], result );
		}
		return dictionary;
	}

	/**
	 * Adds a join to the pivot table for the relationship.
	 *
	 * @return  quick.models.Relationships.BelongsToMany
	 */
	public BelongsToMany function performJoin( any base = variables.relationshipBuilder ) {
		var join      = newJoinClause( arguments.base, variables.table );
		var pivotKeys = getQualifiedRelatedPivotKeyNames();
		for ( var i = 1; i <= variables.relatedKeys.len(); i++ ) {
			join.on( variables.related.qualifyColumn( variables.relatedKeys[ i ] ), pivotKeys[ i ] );
		}
		attachJoinClause( arguments.base, join );
		return this;
	}

	/**
	 * Adds the where constraints for the relationship.
	 *
	 * @return  quick.models.Relationships.BelongsToMany
	 */
	public BelongsToMany function addWhereConstraints() {
		var pivotKeys   = getQualifiedForeignPivotKeyNames();
		var constraints = variables.relationshipBuilder.getQB().forNestedWhere();
		for ( var i = 1; i <= pivotKeys.len(); i++ ) {
			constraints.where( pivotKeys[ i ], variables.parent.retrieveAttribute( variables.parentKeys[ i ] ) );
		}
		variables.relationshipBuilder.getQB().addNestedWhereQuery( constraints );
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
		var qualifiedPivotKeys = [];
		for ( var relatedPivotKey in variables.relatedPivotKeys ) {
			qualifiedPivotKeys.append( listLast( variables.table, " " ) & "." & relatedPivotKey );
		}
		return qualifiedPivotKeys;
	}

	/**
	 * Get's the qualified foreign pivot key column name.
	 * Qualified columns are "table.column".
	 *
	 * @doc_generic  String
	 * @return       [String]
	 */
	public array function getQualifiedForeignPivotKeyNames() {
		var qualifiedPivotKeys = [];
		for ( var foreignPivotKey in variables.foreignPivotKeys ) {
			qualifiedPivotKeys.append( listLast( variables.table, " " ) & "." & foreignPivotKey );
		}
		return qualifiedPivotKeys;
	}

	/**
	 * Includes additional intermediate-table columns on each related entity's Pivot model.
	 * Accepts a column name, comma-delimited list, or array.
	 *
	 * @columns  The pivot columns to include.
	 *
	 * @return   quick.models.Relationships.BelongsToMany
	 */
	public BelongsToMany function withPivot( required any columns ) {
		var normalizedColumns = isArray( arguments.columns )
		 ? arguments.columns
		 : listToArray( arguments.columns );

		for ( var column in normalizedColumns ) {
			if ( !variables.pivotColumns.findNoCase( column ) ) {
				variables.pivotColumns.append( column );
			}
		}

		addPivotSelects();
		return this;
	}

	/**
	 * Uses a custom loaded-relationship name instead of `pivot`.
	 */
	public BelongsToMany function as( required string accessor ) {
		if ( !len( trim( arguments.accessor ) ) ) {
			throw( type = "QuickInvalidPivotAccessor", message = "A pivot accessor cannot be empty." );
		}
		variables.pivotAccessor = arguments.accessor;
		return this;
	}

	/**
	 * Uses a custom Pivot entity mapping for hydrated intermediate rows.
	 */
	public BelongsToMany function using( required string pivotEntity ) {
		if ( !len( trim( arguments.pivotEntity ) ) ) {
			throw( type = "QuickInvalidPivotModel", message = "A custom pivot model mapping cannot be empty." );
		}
		variables.pivotEntity = arguments.pivotEntity;
		return this;
	}

	/**
	 * Includes and maintains timestamp columns on pivot writes.
	 */
	public BelongsToMany function withTimestamps( string createdAt = "created_at", string modifiedAt = "updated_at" ) {
		variables.pivotTimestampColumns = [
			arguments.createdAt,
			arguments.modifiedAt
		];
		return withPivot( variables.pivotTimestampColumns );
	}

	/**
	 * Adds a where constraint using a qualified pivot column.
	 */
	public BelongsToMany function wherePivot(
		required string column,
		any operator,
		any value,
		string combinator = "and"
	) {
		if ( !arguments.keyExists( "value" ) || isNull( arguments.value ) ) {
			arguments.value    = arguments.operator;
			arguments.operator = "=";
		}
		variables.relationshipBuilder.where(
			column     = qualifyPivotColumn( arguments.column ),
			operator   = arguments.operator,
			value      = arguments.value,
			combinator = arguments.combinator
		);
		return this;
	}

	/**
	 * Adds an or-where constraint using a qualified pivot column.
	 */
	public BelongsToMany function orWherePivot(
		required string column,
		any operator,
		any value
	) {
		arguments.combinator = "or";
		return wherePivot( argumentCollection = arguments );
	}

	/**
	 * Adds a where-in constraint using a qualified pivot column.
	 */
	public BelongsToMany function wherePivotIn(
		required string column,
		required any values,
		string combinator = "and"
	) {
		variables.relationshipBuilder.whereIn(
			qualifyPivotColumn( arguments.column ),
			arguments.values,
			arguments.combinator
		);
		return this;
	}

	/**
	 * Adds a where-not-in constraint using a qualified pivot column.
	 */
	public BelongsToMany function wherePivotNotIn(
		required string column,
		required any values,
		string combinator = "and"
	) {
		variables.relationshipBuilder.whereNotIn(
			qualifyPivotColumn( arguments.column ),
			arguments.values,
			arguments.combinator
		);
		return this;
	}

	/**
	 * Adds a where-between constraint using a qualified pivot column.
	 */
	public BelongsToMany function wherePivotBetween(
		required string column,
		required any start,
		required any end,
		string combinator = "and"
	) {
		variables.relationshipBuilder.whereBetween(
			qualifyPivotColumn( arguments.column ),
			arguments.start,
			arguments.end,
			arguments.combinator
		);
		return this;
	}

	/**
	 * Adds a where-not-between constraint using a qualified pivot column.
	 */
	public BelongsToMany function wherePivotNotBetween(
		required string column,
		required any start,
		required any end,
		string combinator = "and"
	) {
		variables.relationshipBuilder.whereNotBetween(
			qualifyPivotColumn( arguments.column ),
			arguments.start,
			arguments.end,
			arguments.combinator
		);
		return this;
	}

	/**
	 * Adds a where-null constraint using a qualified pivot column.
	 */
	public BelongsToMany function wherePivotNull( required string column, string combinator = "and" ) {
		variables.relationshipBuilder.whereNull( qualifyPivotColumn( arguments.column ), arguments.combinator );
		return this;
	}

	/**
	 * Adds a where-not-null constraint using a qualified pivot column.
	 */
	public BelongsToMany function wherePivotNotNull( required string column, string combinator = "and" ) {
		variables.relationshipBuilder.whereNotNull( qualifyPivotColumn( arguments.column ), arguments.combinator );
		return this;
	}

	/**
	 * Orders the related results using a qualified pivot column.
	 */
	public BelongsToMany function orderByPivot( required string column, string direction = "asc" ) {
		variables.relationshipBuilder.orderBy( qualifyPivotColumn( arguments.column ), arguments.direction );
		return this;
	}

	/**
	 * Orders the related results descending using a qualified pivot column.
	 */
	public BelongsToMany function orderByPivotDesc( required string column ) {
		return orderByPivot( arguments.column, "desc" );
	}

	/**
	 * Constrains a pivot value and uses it as a default for pivot writes.
	 */
	public BelongsToMany function withPivotValue( required string column, required any value ) {
		variables.pivotValues[ arguments.column ] = arguments.value;
		withPivot( arguments.column );
		return wherePivot( arguments.column, arguments.value );
	}

	/**
	 * Adds any pivot columns not already present to the related select list.
	 */
	private void function addPivotSelects() {
		addPivotSelectColumns( variables.foreignPivotKeys );
		addPivotSelectColumns( variables.relatedPivotKeys );
		addPivotSelectColumns( variables.pivotColumns );
	}

	private void function addPivotSelectColumns( required array columns ) {
		for ( var column in arguments.columns ) {
			if ( variables.pivotColumnAliases.keyExists( column ) ) {
				continue;
			}

			var aliasName                          = "__quick_pivot_#variables.pivotColumnAliases.count() + 1#";
			variables.pivotColumnAliases[ column ] = aliasName;
			variables.relationshipBuilder.addSelect( "#qualifyPivotColumn( column )# AS #aliasName#" );
			variables.relationshipBuilder.appendVirtualAttribute( name = aliasName, excludeFromMemento = true );
		}
	}

	/**
	 * Hydrates and assigns a Pivot model to a related entity.
	 */
	private any function hydratePivot( required any entity ) {
		if ( !structKeyExists( arguments.entity, "isQuickEntity" ) ) {
			return arguments.entity;
		}

		var attributes = {};
		for ( var column in variables.pivotColumnAliases ) {
			var value            = arguments.entity.retrieveAttribute( variables.pivotColumnAliases[ column ] );
			attributes[ column ] = isNull( value ) ? javacast( "null", "" ) : value;
		}

		var hasCustomPivot = len( variables.pivotEntity ) > 0;
		var mapping        = hasCustomPivot ? variables.pivotEntity : "Pivot@quick";
		var pivot          = variables.wirebox.getInstance( mapping );
		if ( !structKeyExists( pivot, "isPivot" ) ) {
			throw(
				type    = "QuickInvalidPivotModel",
				message = "The custom pivot model [#mapping#] must extend [quick.models.Relationships.Pivot]."
			);
		}

		if ( hasCustomPivot ) {
			for ( var attributeName in attributes ) {
				if ( !pivot.hasAttribute( attributeName ) ) {
					throw(
						type    = "QuickPivotAttributeNotFound",
						message = "The pivot attribute [#attributeName#] is not declared on [#mapping#]."
					);
				}
			}
		}

		var keyNames = [];
		keyNames.append( variables.foreignPivotKeys, true );
		keyNames.append( variables.relatedPivotKeys, true );

		pivot.configurePivot(
			table      = listFirst( variables.table, " " ),
			keyNames   = keyNames,
			attributes = attributes,
			parent     = variables.parent,
			related    = arguments.entity
		);
		arguments.entity.assignRelationship( variables.pivotAccessor, pivot );
		return arguments.entity;
	}

	/**
	 * Qualifies a pivot column unless it is already qualified.
	 */
	private string function qualifyPivotColumn( required string column ) {
		return find( ".", arguments.column ) ? arguments.column : "#listLast( variables.table, " " )#.#arguments.column#";
	}

	/**
	 * Creates a new related entity and attaches it to the parent through the pivot table.
	 *
	 * @attributes                   Attributes for the related entity.
	 * @pivotAttributes              Additional attributes for the pivot row.
	 * @ignoreNonExistentAttributes  Whether to ignore attributes not defined on the related entity.
	 * @options                      Options passed to the related entity save query.
	 *
	 * @return  quick.models.BaseEntity
	 */
	public any function create(
		struct attributes                   = {},
		struct pivotAttributes              = {},
		boolean ignoreNonExistentAttributes = false,
		struct options                      = {}
	) {
		var entity = variables.related.create(
			arguments.attributes,
			arguments.ignoreNonExistentAttributes,
			arguments.options
		);
		attach( entity, arguments.pivotAttributes );
		return entity;
	}

	/**
	 * Associates one or more ids of the related entity to the parent entity.
	 *
	 * @id               The id or array of ids of the related entity.
	 * @pivotAttributes  Additional attributes for each inserted pivot row.
	 *
	 * @return  quick.models.BaseEntity
	 */
	public any function attach( required any id, struct pivotAttributes = {} ) {
		var attributes = buildPivotWriteAttributes( arguments.pivotAttributes, true );
		variables.newPivotStatement().insert( parseIdsForInsert( arguments.id, attributes ) );
		return variables.parent;
	}

	/**
	 * Updates an existing intermediate-table row for the parent and related id.
	 *
	 * @id               The related entity id or composite id values.
	 * @pivotAttributes  The pivot values to update. Pivot keys cannot be overwritten.
	 *
	 * @return           The number of updated rows.
	 */
	public any function updateExistingPivot( required any id, required struct pivotAttributes ) {
		var attributes = buildPivotWriteAttributes( arguments.pivotAttributes, false );
		for ( var key in variables.foreignPivotKeys ) {
			attributes.delete( key );
		}
		for ( var key in variables.relatedPivotKeys ) {
			attributes.delete( key );
		}

		var query = variables.newPivotStatement();
		for ( var i = 1; i <= variables.foreignPivotKeys.len(); i++ ) {
			query.where(
				variables.foreignPivotKeys[ i ],
				variables.parent.retrieveAttribute( variables.parentKeys[ i ] )
			);
		}
		var relatedIds = parseIds( arguments.id )[ 1 ];
		for ( var i = 1; i <= variables.relatedPivotKeys.len(); i++ ) {
			query.where( variables.relatedPivotKeys[ i ], relatedIds[ i ] );
		}

		return query.update( attributes );
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
		var foreignPivotKeyValues = [];
		for ( var parentKey in variables.parentKeys ) {
			foreignPivotKeyValues.append( variables.parent.retrieveAttribute( parentKey ) );
		}
		var parsedIds         = parseIds( arrayWrap( arguments.id ) );
		var pivotQuery        = variables.newPivotStatement();
		var parentConstraints = pivotQuery.getQB().forNestedWhere();
		for ( var i = 1; i <= variables.foreignPivotKeys.len(); i++ ) {
			parentConstraints.where( variables.foreignPivotKeys[ i ], foreignPivotKeyValues[ i ] );
		}
		pivotQuery.getQB().addNestedWhereQuery( parentConstraints );
		var relatedConstraints = pivotQuery.getQB().forNestedWhere();
		for ( var ids in parsedIds ) {
			var idConstraints = relatedConstraints.forNestedWhere();
			for ( var i = 1; i <= variables.relatedPivotKeys.len(); i++ ) {
				idConstraints.where( variables.relatedPivotKeys[ i ], ids[ i ] );
			}
			relatedConstraints.addNestedWhereQuery( idConstraints, "or" );
		}
		pivotQuery.getQB().addNestedWhereQuery( relatedConstraints );
		pivotQuery.delete();
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
	public any function sync( required any id, struct pivotAttributes = {} ) {
		var foreignPivotKeyValues = [];
		for ( var parentKey in variables.parentKeys ) {
			foreignPivotKeyValues.append( variables.parent.retrieveAttribute( parentKey ) );
		}
		var pivotQuery        = variables.newPivotStatement();
		var parentConstraints = pivotQuery.getQB().forNestedWhere();
		for ( var i = 1; i <= variables.foreignPivotKeys.len(); i++ ) {
			parentConstraints.where( variables.foreignPivotKeys[ i ], foreignPivotKeyValues[ i ] );
		}
		pivotQuery.getQB().addNestedWhereQuery( parentConstraints );
		pivotQuery.delete();
		return attach( arguments.id, arguments.pivotAttributes );
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
		var ids = [];
		for ( var val in arrayWrap( arguments.value ) ) {
			// If the value is not a simple value, we will assume
			// it is an entity and return its key value.
			if ( isObject( val ) ) {
				ids.append( val.keyValues() );
			} else {
				ids.append( arrayWrap( val ) );
			}
		}
		return ids;
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
	public array function parseIdsForInsert( required any value, struct pivotAttributes = {} ) {
		var foreignPivotKeyValues = [];
		for ( var parentKey in variables.parentKeys ) {
			foreignPivotKeyValues.append( variables.parent.retrieveAttribute( parentKey ) );
		}
		var additionalPivotAttributes = arguments.pivotAttributes;
		var insertRecords             = [];
		for ( var values in arrayWrap( arguments.value ) ) {
			// If the value is not a simple value, we will assume
			// it is an entity and return its key value.
			if ( isObject( values ) ) {
				values = values.keyValues();
			} else {
				values = arrayWrap( values );
			}
			var insertRecord = {};
			for ( var i = 1; i <= variables.foreignPivotKeys.len(); i++ ) {
				insertRecord[ variables.foreignPivotKeys[ i ] ] = foreignPivotKeyValues[ i ];
				insertRecord[ variables.relatedPivotKeys[ i ] ] = values[ i ];
			}
			insertRecord.append( additionalPivotAttributes, false );
			insertRecords.append( insertRecord );
		}
		return insertRecords;
	}

	/**
	 * Combines configured and supplied values and maintains pivot timestamps.
	 */
	private struct function buildPivotWriteAttributes( struct attributes = {}, boolean inserting = false ) {
		var values = {};
		values.append( variables.pivotValues, true );
		values.append( arguments.attributes, true );

		if ( variables.pivotTimestampColumns.len() == 2 ) {
			var timestamp = now();
			if ( arguments.inserting && !values.keyExists( variables.pivotTimestampColumns[ 1 ] ) ) {
				values[ variables.pivotTimestampColumns[ 1 ] ] = timestamp;
			}
			if ( !values.keyExists( variables.pivotTimestampColumns[ 2 ] ) ) {
				values[ variables.pivotTimestampColumns[ 2 ] ] = timestamp;
			}
		}

		return values;
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

		var query = arguments.base
			.newQuery()
			.select( arguments.base.raw( 1 ) )
			.from( variables.table );
		var foreignKeyNames = getQualifiedForeignKeyNames();
		var parentKeyNames  = variables.parent.retrieveQualifiedKeyNames();
		var qb              = queryBuilderFor( query );
		var constraints     = qb.forNestedWhere();
		for ( var i = 1; i <= foreignKeyNames.len(); i++ ) {
			constraints.whereColumn( foreignKeyNames[ i ], parentKeyNames[ i ] );
		}
		qb.addNestedWhereQuery( constraints );
		return query;
	}

	public any function addNestedCompareConstraints( required any base, required any nested ) {
		arguments.base.select( arguments.base.raw( 1 ) );
		var existsQuery = arguments.base
			.newQuery()
			.selectRaw( 1 )
			.from( variables.table );
		var relatedPivotKeyNames = getQualifiedRelatedPivotKeyNames();
		var relatedKeyNames      = variables.related.retrieveQualifiedKeyNames();
		for ( var i = 1; i <= relatedPivotKeyNames.len(); i++ ) {
			existsQuery.whereColumn( relatedPivotKeyNames[ i ], relatedKeyNames[ i ] );
		}

		var nestedQuery = isBoolean( arguments.nested ) ? existsQuery : arguments.nested
			.clone()
			.select( arguments.base.raw( 1 ) );
		var foreignKeyNames = getQualifiedForeignKeyNames();
		var parentKeyNames  = variables.parent.retrieveQualifiedKeyNames();
		for ( var j = 1; j <= foreignKeyNames.len(); j++ ) {
			nestedQuery.whereColumn( foreignKeyNames[ j ], parentKeyNames[ j ] );
		}

		if ( !isBoolean( arguments.nested ) ) {
			if ( structKeyExists( nestedQuery, "retrieveQuery" ) ) {
				nestedQuery = nestedQuery.retrieveQuery();
			}
			if ( structKeyExists( nestedQuery, "getQB" ) ) {
				nestedQuery = nestedQuery.getQB();
			}
			existsQuery.whereExists( nestedQuery );
		}
		arguments.base.whereExists( existsQuery );
		return arguments.base;
	}

	function nestCompareConstraints( required any base, required any nested ) {
		return structKeyExists( arguments.nested, "retrieveQuery" ) ? arguments.nested.retrieveQuery() : arguments.nested;
	}

	/**
	 * Returns the fully-qualified column name of foreign key.
	 *
	 * @doc_generic  String
	 * @return       [String]
	 */
	public array function getQualifiedForeignKeyNames( any builder = variables.relationshipBuilder ) {
		return getQualifiedForeignPivotKeyNames( arguments.builder );
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
	public any function applyAliasSuffix( required string suffix ) {
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

		var pivotKeys = getQualifiedRelatedPivotKeyNames();
		for ( var i = 1; i <= variables.relatedKeys.len(); i++ ) {
			base.whereColumn( variables.related.qualifyColumn( variables.relatedKeys[ i ] ), pivotKeys[ i ] );
		}

		return variables.related
			.newQuery()
			.reselectRaw( 1 )
			.whereExists( structKeyExists( base, "isBuilder" ) ? base : base.getQB() );
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
		var foreignPivotKeys = getQualifiedForeignPivotKeyNames();
		for ( var i = 1; i <= variables.foreignKeys.len(); i++ ) {
			arguments.base.whereColumn(
				variables.parent.qualifyColumn( variables.foreignKeys[ i ] ),
				foreignPivotKeys[ i ]
			);
		}

		// nest in where exists for pivot table
		arguments.base = variables.parent
			.newQuery()
			.reselectRaw( 1 )
			.from( variables.table )
			.whereExists( structKeyExists( arguments.base, "isBuilder" ) ? arguments.base : arguments.base.getQB() );

		// apply compare constraints for base table
		var relatedPivotKeys = getQualifiedRelatedPivotKeyNames();
		for ( var j = 1; j <= variables.relatedKeys.len(); j++ ) {
			arguments.base.whereColumn(
				variables.related.qualifyColumn( variables.relatedKeys[ j ] ),
				relatedPivotKeys[ j ]
			);
		}

		// nest in where exists for base table
		return variables.related
			.newQuery()
			.reselectRaw( 1 )
			.whereExists( structKeyExists( arguments.base, "isBuilder" ) ? arguments.base : arguments.base.getQB() );
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
		var join      = newJoinClause( arguments.base, variables.parent.tableName() );
		var pivotKeys = getQualifiedForeignPivotKeyNames();
		for ( var i = 1; i <= variables.parentKeys.len(); i++ ) {
			join.on( variables.parent.qualifyColumn( variables.parentKeys[ i ] ), pivotKeys[ i ] );
		}
		attachJoinClause( arguments.base, join );
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
		var query       = queryBuilderFor( arguments.base );
		var localKeys   = getQualifiedForeignPivotKeyNames();
		var constraints = query.forNestedWhere();
		for ( var i = 1; i <= localKeys.len(); i++ ) {
			constraints.where(
				variables.related.qualifyColumn( localKeys[ i ] ),
				variables.parent.retrieveAttribute( variables.parentKeys[ i ] )
			);
		}
		query.addNestedWhereQuery( constraints );
	}

	public struct function appendToDeepRelationship(
		required array through,
		required array foreignKeys,
		required array localKeys,
		required numeric position
	) {
		arguments.through.append( variables.table );

		if ( variables.foreignPivotKeys.len() == 1 ) {
			arguments.foreignKeys.append( variables.foreignPivotKeys, true );
		} else {
			arguments.foreignKeys.append( variables.foreignPivotKeys );
		}

		if ( variables.relatedKeys.len() == 1 ) {
			arguments.foreignKeys.append( variables.relatedKeys, true );
		} else {
			arguments.foreignKeys.append( variables.relatedKeys );
		}

		if ( variables.parentKeys.len() == 1 ) {
			arguments.localKeys.append( variables.parentKeys, true );
		} else {
			arguments.localKeys.append( variables.parentKeys );
		}

		if ( variables.relatedPivotKeys.len() == 1 ) {
			arguments.localKeys.append( variables.relatedPivotKeys, true );
		} else {
			arguments.localKeys.append( variables.relatedPivotKeys );
		}

		return {
			"through"     : arguments.through,
			"foreignKeys" : arguments.foreignKeys,
			"localKeys"   : arguments.localKeys
		};
	}

	public any function getUnloadedDefault() {
		return [];
	}

}
