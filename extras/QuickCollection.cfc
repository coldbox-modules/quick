/**
 * QuickCollection extends CFCollection with some nice additions.
 * However, since CFCollection has some performance issues on some engines
 * due to supporting old engines, it is included in the extras.
 */
component extends="cfcollection.models.Collection" {

	/**
	 * Returns a new QuickCollection for the passed in data.
	 *
	 * @data     The data to collect.
	 *
	 * @return   QuickCollection
	 */
	public QuickCollection function collect( required any data ) {
		return new QuickCollection( arguments.data );
	}

	/**
	 * Eager loads the given relation or array of relations.
	 * Nested relations can be loaded using dot-notation ("posts.comments").
	 * The current collection (now with the relation loaded) is returned.
	 *
	 * @relationName  The relation to load.  It can be passed a single relation
	 *                or an array of relations.  Nested relations can be loaded
	 *                using dot-notation ("posts.comments").
	 *
	 * @return        QuickCollection
	 */
	public QuickCollection function load( required any relationName ) {
		if ( this.empty() ) {
			return this;
		}

		if ( !isArray( arguments.relationName ) ) {
			arguments.relationName = [ arguments.relationName ];
		}

		for ( var relation in arguments.relationName ) {
			variables.eagerLoadRelation( relation );
		}

		return this;
	}

	/**
	 * Returns an array of each item's mementos.
	 *
	 * @return [any]
	 */
	public array function getMemento() {
		return this
			.map( function( entity ) {
				return arguments.entity.$renderData();
			} )
			.get();
	}

	/**
	 * ColdBox magic method to return the result of the `getMemento` call
	 * when returning a QuickCollection directly from a handler.
	 *
	 * @return   [any]
	 */
	function $renderData() {
		return variables.getMemento();
	}

	/**
	 * Eager loads a single relation for the entities in the collection.
	 * This is useful if you later want to eager load based on some condition
	 * rather than when retrieving the results initially.
	 *
	 * @relationName  The relation to load.
	 *
	 * @return        void
	 */
	private void function eagerLoadRelation( required string relationName ) {
		var relation         = invoke( get( 1 ), arguments.relationName ).resetQuery();
		var hasMatches       = relation.addEagerConstraints( get() );
		variables.collection = relation.match(
			relation.initRelation( get(), arguments.relationName ),
			hasMatches ? relation.getEager() : [],
			arguments.relationName
		);
	}

}
