/**
 * Represents a belongsTo relationship.
 *
 * This is a relationship where the related entity belongs to
 * exactly one of the parent entity. The inverse of this relationship
 * is a `hasMany` relationship.
 *
 * For instance, a `Post` may belong to a `User` which we can call an author.
 * This would be modeled in Quick by adding a method to the `Post` entity
 * that returns a `BelongsTo` relationship instance.
 *
 * ```
 * function author() {
 *     returns belongsTo( "User" );
 * }
 * ```
 */
component extends="quick.models.Relationships.BaseRelationship" accessors="true" {

	/**
	 * An alias for the parent entity.
	 */
	property name="child";

	/**
	 * The column names on the `parent` entity that refers to
	 * the `localKeys` on the `related` entity.
	 */
	property name="foreignKeys" type="array";

	/**
	 * The column names on the `realted` entity that is referred
	 * to by the `foreignKeys` of the `parent` entity.
	 */
	property name="localKeys" type="array";

	/**
	 * Used to check for the type of relationship more quickly than using isInstanceOf.
	 */
	this.relationshipClass = "BelongsTo";

	/**
	 * Creates a belongsTo relationship.
	 *
	 * @related             The related entity instance.
	 * @relationName        The WireBox mapping for the related entity.
	 * @relationMethodName  The method name called to retrieve this relationship.
	 * @parent              The parent entity instance for the relationship.
	 *                      In a `BelongsTo` relationship, this is also referred
	 *                      to internally as `child`.
	 * @foreignKeys         The column names on the `parent` entity that refers to
	 *                      the `localKeys` on the `related` entity.
	 * @localKeys           The column names on the `realted` entity that is referred
	 *                      to by the `foreignKeys` of the `parent` entity.
	 *
	 * @return              quick.models.Relationships.BelongsTo
	 */
	public BelongsTo function init(
		required any related,
		required string relationName,
		required string relationMethodName,
		required any parent,
		required array foreignKeys,
		required array localKeys,
		boolean withConstraints = true
	) {
		variables.localKeys   = arguments.localKeys;
		variables.foreignKeys = arguments.foreignKeys;
		variables.child       = arguments.parent;

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
	 * If a null is returned, an optional default model can be returned.
	 * The default model can be configured using a `withDefault` method.
	 *
	 * @return  quick.models.BaseEntity | null
	 */
	public any function getResults() {
		var result = (
			fieldsAreNull( entity = variables.child, fields = variables.foreignKeys )
			 ? javacast( "null", "" )
			 : variables.related.first()
		);

		if ( !isNull( result ) ) {
			return result;
		}

		if ( !variables.returnDefaultEntity ) {
			return javacast( "null", "" );
		}

		if ( isClosure( variables.defaultAttributes ) || isCustomFunction( variables.defaultAttributes ) ) {
			return tap( variables.related.newEntity(), function( newEntity ) {
				variables.defaultAttributes( newEntity, variables.child );
			} );
		}

		return variables.related.newEntity().fill( variables.defaultAttributes );
	}

	/**
	 * Adds the constraints to the related entity.
	 *
	 * @return  void
	 */
	public void function addConstraints() {
		variables.related.where( function( q ) {
			arrayZipEach(
				[
					variables.localKeys,
					variables.foreignKeys
				],
				function( localKey, foreignKey ) {
					q.where(
						variables.related.qualifyColumn( localKey ),
						variables.child.retrieveAttribute( foreignKey )
					);
				}
			);
		} );
	}

	/**
	 * Adds the constraints for eager loading.
	 *
	 * @entities  The entities being eager loaded.
	 *
	 * @return    quick.models.Relationships.BelongsTo
	 */
	public boolean function addEagerConstraints( required array entities ) {
		var allKeys = getEagerEntityKeys( entities );
		if ( allKeys.isEmpty() ) {
			return false;
		}
		variables.related.where( function( q1 ) {
			allKeys.each( function( keys ) {
				q1.orWhere( function( q2 ) {
					arrayZipEach( [ variables.localKeys, keys ], function( localKey, key ) {
						q2.where(
							variables.related.qualifyColumn( localKey ),
							variables.related.generateQueryParamStruct( localKey, key )
						);
					} );
				} );
			} );
		} );
		return true;
	}

	/**
	 * Returns an array of entity keys for the entities being eager loaded.
	 *
	 * @entities     The entities being eager loaded.
	 *
	 * @doc_generic  any
	 * @return       [any]
	 */
	public array function getEagerEntityKeys( required array entities ) {
		return arguments.entities
			.reduce( function( keys, entity ) {
				var values = variables.foreignKeys
					.map( function( foreignKey ) {
						return {
							"foreignKey" : foreignKey,
							"value"      : entity.retrieveAttribute( foreignKey )
						};
					} )
					.filter( function( map ) {
						if ( !structKeyExists( map, "value" ) ) {
							return false;
						}

						if ( isNull( map.value ) ) {
							return false;
						}

						if ( !entity.hasAttribute( map.foreignKey ) ) {
							return false;
						}

						if ( entity.isNullValue( map.foreignKey, map.value ) ) {
							return false;
						}

						return true;
					} )
					.map( function( map ) {
						return map.value;
					} );

				if ( values.len() == variables.foreignKeys.len() ) {
					arguments.keys[ values.toList() ] = {};
				}

				return arguments.keys;
			}, {} )
			.keyArray()
			.map( function( key ) {
				return key.listToArray();
			} );
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
		arguments.entities.each( function( entity ) {
			arguments.entity.assignRelationship( relation, javacast( "null", "" ) );
		} );
		return arguments.entities;
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
		var dictionary = arguments.results.reduce( function( dict, result ) {
			var key = variables.localKeys
				.map( function( localKey ) {
					return result.retrieveAttribute( localKey );
				} )
				.toList();
			arguments.dict[ key ] = arguments.result;
			return arguments.dict;
		}, {} );

		arguments.entities.each( function( entity ) {
			var foreignKeyValue = variables.foreignKeys
				.map( function( foreignKey ) {
					return entity.retrieveAttribute( foreignKey );
				} )
				.toList();
			if ( structKeyExists( dictionary, foreignKeyValue ) ) {
				arguments.entity.assignRelationship( relation, dictionary[ foreignKeyValue ] );
			}
		} );

		return arguments.entities;
	}

	/**
	 * Associates the given entity when the relationship is used as a setter.
	 *
	 * Relationships on entities can be called with `set` in front of it.
	 * If it is, a `BelongsTo` relationship forwards the call to `associate`.
	 *
	 * @entity  The entity or entity id to associate as the new owner.
	 *          If an entity is passed, it is also cached in the child entity
	 *          as the value for the relationship.
	 *
	 * @return  quick.models.BaseEntity
	 */
	public any function applySetter() {
		return associate( argumentCollection = arguments );
	}

	/**
	 * Sets a new entity as the parent of the relationship.
	 * For example, if a Post belongs to a User, associate will set
	 * the foreign key on the Post table to the User's id.
	 *
	 * @entity  The entity or entity id to associate as the new owner.
	 *          If an entity is passed, it is also cached in the child entity
	 *          as the value for the relationship.
	 *
	 * @return  quick.models.BaseEntity
	 */
	public any function associate( required any entity ) {
		var localKeyValues = !isObject( arguments.entity ) ? arrayWrap( arguments.entity ) : variables.localKeys.map( function( localKey ) {
			return entity.retrieveAttribute( localKey );
		} );

		guardAgainstKeyLengthMismatch( localKeyValues, variables.foreignKeys );

		arrayZipEach(
			[
				variables.foreignKeys,
				localKeyValues
			],
			function( foreignKey, localKeyValue ) {
				variables.child.forceAssignAttribute( foreignKey, localKeyValue );
			}
		);

		if ( isObject( arguments.entity ) ) {
			variables.child.assignRelationship( variables.relationMethodName, arguments.entity );
		}

		return variables.child;
	}

	/**
	 * Removes an entity as the parent of the relationship.
	 * For example, if a Post belongs to a User, dissociate will set the
	 * foreign key column on the Post entity to null.
	 *
	 * @return  quick.models.BaseEntity
	 */
	public any function dissociate() {
		return tap( variables.child.clearRelationship( variables.relationMethodName ), function( entity ) {
			variables.foreignKeys.each( function( foreignKey ) {
				entity.forceClearAttribute( name = foreignKey, setToNull = true );
			} );
		} );
	}

	/**
	 * Returns the fully-qualified local key.
	 *
	 * @doc_generic  String
	 * @return       [String]
	 */
	public array function getQualifiedLocalKeys() {
		return variables.localKeys.map( function( localKey ) {
			return variables.related.qualifyColumn( localKey );
		} );
	}

	/**
	 * Get the key to compare in the existence query.
	 *
	 * @doc_generic  String
	 * @return       [String]
	 */
	public array function getExistenceCompareKeys() {
		return variables.foreignKeys.map( function( foreignKey ) {
			return variables.child.qualifyColumn( foreignKey );
		} );
	}

	/**
	 * Applies the join for relationship in a `hasManyThrough` chain.
	 *
	 * @base    The query to apply the join to.
	 *
	 * @return  void
	 */
	public QuickBuilder function applyThroughExists( required QuickBuilder base ) {
		arrayZipEach(
			[
				variables.foreignKeys,
				variables.localKeys
			],
			function( foreignKey, localKey ) {
				base.whereColumn(
					variables.child.qualifyColumn( foreignKey ),
					variables.related.qualifyColumn( localKey )
				);
			}
		);
		return variables.related
			.newQuery()
			.reselectRaw( 1 )
			.whereExists( arguments.base );
	}

	public QuickBuilder function initialThroughConstraints() {
		var base = variables.related.newQuery().reselectRaw( 1 );

		arrayZipEach(
			[
				variables.localKeys,
				variables.foreignKeys
			],
			function( localKey, foreignKey ) {
				base.where(
					variables.related.qualifyColumn( localKey ),
					variables.parent.retrieveAttribute( foreignKey )
				);
			}
		);

		return base;
	}

	/**
	 * Applies the join for relationship in a `hasManyThrough` chain.
	 *
	 * @base    The query to apply the join to.
	 *
	 * @return  void
	 */
	public void function applyThroughJoin( required any base ) {
		arguments.base.join( variables.child.tableName(), function( j ) {
			arrayZipEach(
				[
					variables.foreignKeys,
					variables.localKeys
				],
				function( foreignKey, localKey ) {
					j.on( variables.child.qualifyColumn( foreignKey ), variables.related.qualifyColumn( localKey ) );
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
		arguments.base.where( function( q ) {
			arrayZipEach(
				[
					variables.foreignKeys,
					variables.localKeys
				],
				function( foreignKey, localKey ) {
					q.where(
						variables.related.qualifyColumn( localKey ),
						variables.child.retrieveAttribute( foreignKey )
					);
				}
			);
		} );
	}

}
