component accessors="true" extends="quick.models.Relationships.BaseRelationship" {

    function init(
        related,
        relationName,
        relationMethodName,
        parent,
        intermediate,
        firstKey,
        secondKey,
        localKey,
        secondLocalKey
    ) {
        variables.throughParent = arguments.intermediate;
        variables.farParent = arguments.parent;

        variables.firstKey = arguments.firstKey;
        variables.secondKey = arguments.secondKey;
        variables.localKey = arguments.localKey;
        variables.secondLocalKey = arguments.secondLocalKey;

        super.init( related, relationName, relationMethodName, intermediate );
    }

    function addConstraints() {
        var localValue = variables.farParent.retrieveAttribute( variables.localKey );
        performJoin();
        variables.related.where(
            getQualifiedFirstKeyName(),
            "=",
            localValue
        );
    }

    function performJoin() {
        var farKey = getQualifiedFarKeyName();
        variables.related.join(
            variables.throughParent.get_Table(),
            getQualifiedParentKeyName(),
            "=",
            farKey
        );
    }

    function getQualifiedFarKeyName() {
        return getQualifiedForeignKeyName();
    }

    function getQualifiedForeignKeyName() {
        return variables.related.qualifyColumn( variables.secondKey );
    }

    function getQualifiedFirstKeyName() {
        return variables.throughParent.qualifyColumn( variables.firstKey );
    }

    function getQualifiedParentKeyName() {
        return variables.parent.qualifyColumn( variables.secondLocalKey );
    }

    function getResults() {
        return this.get();
    }
    
    function get() {
        var entities = variables.related.getEntities();
        if ( entities.len() > 0 ) {
            entities = variables.related.eagerLoadRelations( entities );
        }
        return entities;
    }

    function addEagerConstraints( entities ) {
        performJoin();
        variables.related.whereIn(
            getQualifiedFirstKeyName(),
            getKeys( entities, variables.localKey )
        );
    }

    function initRelation( entities, relation ) {
        entities.each( function( entity ) {
            entity.assignRelationship( relation, [] );
        } );
        return entities;
    }

    function match( entities, results, relation ) {
        var dictionary = buildDictionary( results );
        entities.each( function( entity ) {
            var key = entity.retrieveAttribute( variables.localKey );
            if ( structKeyExists( dictionary, key ) ) {
                entity.assignRelationship( relation, dictionary[ key ] );
            }
        } );
        return entities;
    }

    function buildDictionary( results ) {
        return results.reduce( function( dict, result ) {
            var key = result.retrieveAttribute( variables.firstKey );
            if ( ! structKeyExists( dict, key ) ) {
                dict[ key ] = [];
            }
            arrayAppend( dict[ key ], result );
            return dict;
        }, {} );
    }

}
