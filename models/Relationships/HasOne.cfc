component extends="quick.models.Relationships.HasOneOrMany" {

    function getResults() {
        return variables.related.first();
    }
    
    function get() hint="Wrapper for getResults() for consistency" {
        return getResults();
    }

    function initRelation( entities, relation ) {
        entities.each( function( entity ) {
            entity.assignRelationship( relation, javacast( "null", "" ) );
        } );
        return entities;
    }

    function match( entities, results, relation ) {
        return matchOne( argumentCollection = arguments );
    }

}
