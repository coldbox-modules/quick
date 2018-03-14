component extends="cfcollection.models.Collection" {

    function collect( data ) {
        return new QuickCollection( data );
    }

    function load( relationName ) {
        if ( this.empty() ) {
            return this;
        }

        if ( ! isArray( relationName ) ) {
            relationName = [ relationName ];
        }

        for ( var relation in relationName ) {
            eagerLoadRelation( relation );
        }

        return this;
    }

    private function eagerLoadRelation( relationName ) {
        var keys = map( function( entity ) {
            return invoke( entity, relationName ).getForeignKeyValue();
        } ).unique();
        var relatedEntity = invoke( get( 1 ), relationName ).getRelated();
        var owningKey = invoke( get( 1 ), relationName ).getOwningKey();
        var relations = relatedEntity.whereIn( owningKey, keys.get() ).get();

        return matchRelations( relations, relationName );
    }

    private function matchRelations( relations, relationName ) {
        var relationship = invoke( get( 1 ), relationName );
        var groupedRelations = relations.groupBy( key = relationship.getOwningKey(), forceLookup = true );
        return this.each( function( entity ) {
            var relationship = invoke( entity, relationName );
            if ( structKeyExists( groupedRelations, relationship.getForeignKeyValue() ) ) {
                entity.setRelationship( relationName, groupedRelations[ relationship.getForeignKeyValue() ] );
            }
            else {
                entity.setRelationship( relationName, relationship.getDefaultValue() );
            }
        } );
    }

}
