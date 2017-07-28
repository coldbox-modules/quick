component accessors="true" {

    property name="builder" inject="provider:Builder@qb" getter="false" setter="false";
    property name="wirebox" inject="wirebox" getter="false" setter="false";
    property name="str" inject="Str@str" getter="false" setter="false";

    property name="entityName";
    property name="fullName";
    property name="table";
    property name="key" default="id";

    property name="attributes";
    property name="relationships";

    variables.loaded = false;

    function init() {
        variables.attributes = {};
        variables.relationships = {};
        metadataInspection();
    }

    function all() {
        var attributesArray = builder.get().from( getTable() ).get();
        return attributesArray.map( function( attributes ) {
            return wirebox.getInstance( getFullName() ).setAttributes( attributes );
        } );
    }

    function get() {
        return getQuery().get().map( function( attributes ) {
            return wirebox.getInstance( getFullName() )
                .setAttributes( attributes );
        } );
    }

    function first() {
        return wirebox.getInstance( getFullName() )
            .setAttributes( getQuery().first() );
    }

    function find( id ) {
        var attributes = builder.get().from( getTable() ).find( id, getKey() );
        if ( structIsEmpty( attributes ) ) {
            return;
        }
        return wirebox.getInstance( getFullName() )
            .setAttributes( attributes );
    }

    function isLoaded() {
        return variables.loaded;
    }

    function setAttributes( attributes ) {
        if ( isNull( attributes ) ) {
            variables.loaded = false;
            return this;
        }
        variables.loaded = true;
        variables.attributes = arguments.attributes;
        return this;
    }

    private function getQuery() {
        param variables.query = builder.get().from( getTable() );
        return variables.query;
    }

    private function metadataInspection() {
        var md = getMetadata( this );
        setFullName( md.fullname );
        param md.entityName = listLast( md.name, "." );
        setEntityName( md.entityName );
        param md.table = pluralize( lcase( getEntityName() ) );
        setTable( md.table );
    }

    private function pluralize( word ) {
        // obviously needs to be better
        // probably defer to the Str module
        return word & "s";
    }

    private function belongsTo( mapping, foreignKey ) {
        var related = wirebox.getInstance( mapping );
        if ( isNull( arguments.foreignKey ) ) {
            arguments.foreignKey = lcase( "#related.getEntityName()#_#related.getKey()#" );
        }
        return wirebox.getInstance( name = "BelongsTo@quick", initArguments = {
            related = related,
            foreignKeyValue = variables.attributes[ arguments.foreignKey ]
        } );
    }

    private function hasOne( mapping, foreignKey ) {
        var related = wirebox.getInstance( mapping );
        if ( isNull( arguments.foreignKey ) ) {
            arguments.foreignKey = lcase( "#getEntityName()#_#getKey()#" );
        }
        return wirebox.getInstance( name = "HasOne@quick", initArguments = {
            related = related,
            foreignKey = foreignKey,
            foreignKeyValue = variables.attributes[ getKey() ]
        } );
    }

    private function hasMany( mapping, foreignKey ) {
        var related = wirebox.getInstance( mapping );
        if ( isNull( arguments.foreignKey ) ) {
            arguments.foreignKey = lcase( "#getEntityName()#_#getKey()#" );
        }
        return wirebox.getInstance( name = "HasMany@quick", initArguments = {
            related = related,
            foreignKey = foreignKey,
            foreignKeyValue = variables.attributes[ getKey() ]
        } );
    }

    function onMissingMethod( missingMethodName, missingMethodArguments ) {
        var columnValue = tryColumnName( missingMethodName );
        if ( ! isNull( columnValue ) ) { return columnValue; }
        var q = tryScopes( missingMethodName, missingMethodArguments );
        if ( ! isNull( q ) ) {
            variables.query = q;
            return this;
        }
        var r = tryRelationships( missingMethodName );
        if ( ! isNull( r ) ) { return r; }
        return forwardToQB( missingMethodName, missingMethodArguments );
    }

    private function tryColumnName( missingMethodName ) {
        if ( len( missingMethodName ) < 3 || left( missingMethodName, 3 ) != "get" ) {
            return;
        }

        var columnName = mid( missingMethodName, 4, len( missingMethodName ) - 3 );

        if ( structKeyExists( variables.attributes, columnName ) ) {
            return variables.attributes[ columnName ];
        }

        var snakeCaseColumnName = str.snake( columnName );
        if ( structKeyExists( variables.attributes, snakeCaseColumnName ) ) {
            return variables.attributes[ snakeCaseColumnName ];   
        }

        return;
    }

    private function tryRelationships( missingMethodName ) {
        if ( len( missingMethodName ) < 3 || left( missingMethodName, 3 ) != "get" ) {
            return;
        }

        var relationshipName = mid( missingMethodName, 4, len( missingMethodName ) - 3 );

        if ( ! structKeyExists( variables.relationships, relationshipName ) ) {
            variables.relationships[ relationshipName ] = invoke( this, relationshipName ).retrieve();
        }

        return variables.relationships[ relationshipName ];
    }

    private function tryScopes( missingMethodName, missingMethodArguments ) {
        if ( structKeyExists( variables, "scope#missingMethodName#" ) ) {
            return invoke( this, "scope#missingMethodName#", {
                builder = getQuery(),
                args = missingMethodArguments
            } );
        }
        return;
    }

    private function forwardToQB( missingMethodName, missingMethodArguments ) {
        invoke( getQuery(), missingMethodName, missingMethodArguments );
        return this;
    }

}