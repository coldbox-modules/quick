/**
 * Represents a hasOne relationship.
 *
 * This is a relationship where the parent entity has exactly zero or one of
 * the related entity. The inverse of this relationship is also a `hasOne`
 * relationship.
 *
 * For instance, a `User` may have zero or one `UserProfile` associated to them.
 * This would be modeled in Quick by adding a method to the `User` entity
 * that returns a `HasOne` relationship instance.
 *
 * ```
 * function profile() {
 *     returns hasOne( "UserProfile" );
 * }
 * ```
 */
component extends="quick.models.Relationships.HasOneOrManyThrough" {

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
	 * Initializes the relation to the null value for each entity in an array.
	 *
	 * @entities     The entities to initialize the relation.
	 * @relation     The name of the relation to initialize.
	 *
	 * @doc_generic  quick.models.BaseEntity
	 * @return       [quick.models.BaseEntity]
	 */
	public array function initRelation( required array entities, required string relation ) {
		for ( var entity in arguments.entities ) {
			if ( structKeyExists( entity, "isQuickEntity" ) ) {
				entity.assignRelationship( arguments.relation, [] );
			} else {
				entity[ arguments.relation ] = [];
			}
		}
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
		var dictionary = buildDictionary( arguments.results );
		for ( var entity in arguments.entities ) {
			var keyValues = [];
			for ( var localKey in variables.closestToParent.getLocalKeys() ) {
				keyValues.append(
					structKeyExists( entity, "isQuickEntity" ) ? entity.retrieveAttribute( localKey ) : entity[ localKey ]
				);
			}
			var key = keyValues.toList();
			if ( structKeyExists( dictionary, key ) ) {
				if ( structKeyExists( entity, "isQuickEntity" ) ) {
					entity.assignRelationship( relation, dictionary[ key ] );
				} else {
					entity[ relation ] = dictionary[ key ];
				}
			}
		}
		return arguments.entities;
	}

}
