component extends="quick.models.Relationships.HasOneOrMany" {

    function getResults() {
        return variables.related.first();
    }

    function initRelation( entities, relation ) {
        entities.each( function( entity ) {
            entity.assignRelationship( relation, {} );
        } );
        return entities;
    }

    function match( entities, results, relation ) {
        return matchOne( argumentCollection = arguments );
    }

}
