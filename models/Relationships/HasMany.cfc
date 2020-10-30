/**
 * Represents a hasMany relationship.
 *
 * This is a relationship where the parent entity has zero or more of the related
 * entity. The inverse of this relationship is a `belongsTo` relationship.
 *
 * For instance, a `User` may have zero or more `Post` associated to them.
 * This would be modeled in Quick by adding a method to the `User` entity
 * that returns a `HasMany` relationship instance.
 *
 * ```
 * function posts() {
 *     returns hasMany( "Post" );
 * }
 * ```
 */
component extends="quick.models.Relationships.HasOneOrMany" accessors="true" {

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
		return matchMany( argumentCollection = arguments );
	}

}
