component extends="quick.models.Relationships.PolymorphicHasOneOrMany" {

    function getResults() {
        return variables.related.get();
    }

    function get() hint="Wrapper for getResults() for consistency" {
        return getResults();
    }
    
    function initRelation( entities, relation ) {
        entities.each( function( entity ) {
            entity.assignRelationship( relation, [] );
        } );
        return entities;
    }

    function match( entities, results, relation ) {
        return matchMany( entities, results, relation );
    }

}
