component accessors="true" extends="quick.models.Relationships.BaseRelationship" {

    function init(
        related,
        relationName,
        relationMethodName,
        parent,
        table,
        foreignPivotKey,
        relatedPivotKey,
        parentKey,
        relatedKey
    ) {
        variables.table = arguments.table;
        variables.parentKey = arguments.parentKey;
        variables.relatedKey = arguments.relatedKey;
        variables.relatedPivotKey = arguments.relatedPivotKey;
        variables.foreignPivotKey = arguments.foreignPivotKey;

        super.init( related, relationName, relationMethodName, parent );
    }

    function getResults() {
        return variables.related.get();
    }

    function addConstraints() {
        performJoin();
        addWhereConstraints();
    }

    function addEagerConstraints( entities ) {
        variables.related
            .from( variables.table )
            .whereIn(
                getQualifiedForeignPivotKeyName(),
                getKeys( entities, variables.parentKey )
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
            if ( structKeyExists( dictionary, entity.retrieveAttribute( variables.parentKey ) ) ) {
                entity.assignRelationship(
                    relation,
                    dictionary[ entity.retrieveAttribute( variables.parentKey ) ]
                );
            }
        } );
        return entities;
    }

    function buildDictionary( results ) {
        return results.reduce( function( dict, result ) {
            var key = result.retrieveAttribute( variables.foreignPivotKey );
            if ( ! structKeyExists( dict, key ) ) {
                dict[ key ] = [];
            }
            arrayAppend( dict[ key ], result );
            return dict;
        }, {} );
    }

    function performJoin() {
        var baseTable = variables.related.get_table();
        var key = baseTable & "." & variables.relatedKey;
        variables.related.join( variables.table, key, "=", getQualifiedRelatedPivotKeyName() );
        return this;
    }

    function addWhereConstraints() {
        variables.related.where(
            getQualifiedForeignPivotKeyName(),
            "=",
            variables.parent.retrieveAttribute( variables.parentKey )
        );
        return this;
    }

    function getQualifiedRelatedPivotKeyName() {
        return variables.table & "." & variables.relatedPivotKey;
    }

    function getQualifiedForeignPivotKeyName() {
        return variables.table & "." & variables.foreignPivotKey;
    }

    function attach( id ) {
        newPivotStatement().insert( parseIdsForInsert( id ) );
    }

    function detach( id ) {
        var foreignPivotKeyValue = variables.parent.retrieveAttribute( variables.parentKey );
        newPivotStatement()
            .where( variables.parentKey, "=", foreignPivotKeyValue )
            .whereIn(
                variables.relatedPivotKey,
                parseIds( id )
            ).delete();
    }

    function sync( id ) {
        var foreignPivotKeyValue = variables.parent.retrieveAttribute( variables.parentKey );
        newPivotStatement().where( variables.foreignPivotKey, "=", foreignPivotKeyValue ).delete();
        attach( id );
    }

    function newPivotStatement() {
        return variables.related.newQuery().from( variables.table );
    }

    function parseIds( value ) {
        arguments.value = isArray( value ) ? value : [ value ];
        return arguments.value.map( function( val ) {
            // If the value is not a simple value, we will assume
            // it is an entity and return its key value.
            if ( ! isSimpleValue( val ) ) {
                return val.keyValue();
            }
            return val;
        } );
    }

    function parseIdsForInsert( value ) {
        var foreignPivotKeyValue = variables.parent.retrieveAttribute( variables.parentKey );
        arguments.value = isArray( value ) ? value : [ value ];
        return arguments.value.map( function( val ) {
            // If the value is not a simple value, we will assume
            // it is an entity and return its key value.
            if ( ! isSimpleValue( val ) ) {
                arguments.val = val.keyValue();
            }
            var insertRecord = {};
            insertRecord[ variables.foreignPivotKey ] = foreignPivotKeyValue;
            insertRecord[ variables.relatedPivotKey ] = arguments.val;
            return insertRecord;
        } );
    }

}
