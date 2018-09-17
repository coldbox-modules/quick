component accessors="true" {

    /*====================================
    =            Dependencies            =
    ====================================*/
    property name="_builder"            inject="QuickQB@quick";
    property name="_wirebox"            inject="wirebox";
    property name="_str"                inject="Str@str";
    property name="_settings"           inject="coldbox:modulesettings:quick";
    property name="_validationManager"  inject="ValidationManager@cbvalidation";
    property name="_interceptorService" inject="coldbox:interceptorService";
    property name="_keyType"            inject="AutoIncrementing@quick";

    /*===========================================
    =            Metadata Properties            =
    ===========================================*/
    property name="_entityName";
    property name="_mapping";
    property name="_fullName";
    property name="_table";
    property name="_queryOptions";
    property name="_readonly"        default="false";
    property name="_key"             default="id";
    property name="_attributes";
    property name="_meta";
    property name="_nullValues";

    /*=====================================
    =            Instance Data            =
    =====================================*/
    property name="_data";
    property name="_originalAttributes";
    property name="_relationshipsData";
    property name="_eagerLoad";
    property name="_loaded";

    this.constraints = {};

    variables.relationships = {};

    function init() {
        assignDefaultProperties();
        return this;
    }

    function assignDefaultProperties() {
        assignAttributesData( {} );
        assignOriginalAttributes( {} );
        variables._relationshipsData = {};
        variables._eagerLoad = [];
        variables._nullValues = {};
        variables._loaded = false;
    }

    function onDIComplete() {
        metadataInspection();
    }

    /*==================================
    =            Attributes            =
    ==================================*/

    function keyValue() {
        return variables._data[ variables._key ];
    }

    function retrieveAttributesData( aliased = false, withoutKey = false ) {
        variables._attributes.keyArray().each( function( key ) {
            if ( variables.keyExists( key ) && ! isReadOnlyAttribute( key ) ) {
                assignAttribute( key, variables[ key ] );
            }
        } );
        return variables._data.reduce( function( acc, key, value ) {
            if ( withoutKey && key == variables._key ) {
                return acc;
            }
            acc[ aliased ? retrieveAliasForColumn( key ) : key ] = isNull( value ) ? javacast( "null", "" ) : value;
            return acc;
        }, {} );
    }

    function retrieveAttributeNames( columnNames = false ) {
        return variables._attributes.reduce( function( items, key, value ) {
            items.append( columnNames ? value : key );
            return items;
        }, [] );
    }

    function clearAttribute( name, setToNull = false ) {
        if ( setToNull ) {
            variables._data[ name ] = javacast( "null", "" );
            variables[ retrieveAliasForColumn( name ) ] = javacast( "null", "" );
        }
        else {
            variables._data.delete( name );
            variables.delete( retrieveAliasForColumn( name ) );
        }
        return this;
    }

    function assignAttributesData( attrs ) {
        guardAgainstReadOnlyAttributes( attrs );
        if ( isNull( attrs ) ) {
            variables._loaded = false;
            variables._data = {};
            return this;
        }

        variables._data = attrs.reduce( function( acc, name, value ) {
            var key = name;
            if ( isColumnAlias( name ) ) {
                key = retrieveColumnForAlias( name );
            }
            acc[ key ] = value;
            return acc;
        }, {} );

        for ( var key in variables._data ) {
            variables[ retrieveAliasForColumn( key ) ] = variables._data[ key ];
        }

        return this;
    }

    function fill( attributes ) {
        for ( var key in arguments.attributes ) {
            guardAgainstNonExistentAttribute( key );
            variables._data[ retrieveColumnForAlias( key ) ] = arguments.attributes[ key ];
            invoke( this, "set#retrieveAliasForColumn( key )#", { 1 = arguments.attributes[ key ] } );
        }
        return this;
    }

    function hasAttribute( name ) {
        return structKeyExists( variables._attributes, retrieveAliasForColumn( name ) ) || variables._key == name;
    }

    function isColumnAlias( name ) {
        return structKeyExists( variables._attributes, name );
    }

    function retrieveColumnForAlias( name ) {
        return variables._attributes.keyExists( name ) ? variables._attributes[ name ] : name;
    }

    function retrieveAliasForColumn( name ) {
        return variables._attributes.reduce( function( acc, alias, column ) {
            return name == column ? alias : acc;
        }, name );
    }

    function transformAttributeAliases( attributes ) {
        return arguments.attributes.reduce( function( acc, key, value ) {
            if ( isColumnAlias( key ) ) {
                key = retrieveColumnForAlias( key );
            }
            acc[ key ] = value;
            return acc;
        }, {} );
    }

    function assignOriginalAttributes( attributes ) {
        variables._originalAttributes = duplicate( arguments.attributes );
        return this;
    }

    function isLoaded() {
        return variables._loaded;
    }

    function isDirty() {
        return ! deepEqual( get_OriginalAttributes(), retrieveAttributesData() );
    }

    function retrieveAttribute( name, defaultValue = "" ) {
        return variables._data.keyExists( retrieveColumnForAlias( name ) ) ?
            variables._data[ retrieveColumnForAlias( name ) ] :
            defaultValue;
    }

    function assignAttribute( name, value ) {
        guardAgainstNonExistentAttribute( name );
        guardAgainstReadOnlyAttribute( name );
        variables._data[ retrieveColumnForAlias( name ) ] = value;
        variables[ retrieveAliasForColumn( name ) ] = value;
        return this;
    }

    function qualifyColumn( column ) {
        if ( findNoCase( ".", arguments.column ) != 0 ) {
            return arguments.column;
        }
        return variables._table & "." & arguments.column;
    }

    /*=====================================
    =            Query Methods            =
    =====================================*/

    function getEntities() {
        return retrieveQuery()
            .get( options = variables._queryOptions )
            .map( function( attributes ) {
                return newEntity()
                    .assignAttributesData( attributes )
                    .assignOriginalAttributes( attributes )
                    .set_Loaded( true );
            } )
    }

    function all() {
        return eagerLoadRelations(
            newQuery().from( variables._table )
                .get( options = variables._queryOptions )
                .map( function( attributes ) {
                    return newEntity()
                        .assignAttributesData( attributes )
                        .assignOriginalAttributes( attributes )
                        .set_Loaded( true );
                } )
        );
    }

    function get() {
        return eagerLoadRelations( getEntities() );
    }

    function first() {
        var attributes = retrieveQuery().first( options = variables._queryOptions );
        return newEntity()
            .assignAttributesData( attributes )
            .assignOriginalAttributes( attributes )
            .set_Loaded( ! structIsEmpty( attributes ) );
    }

    function find( id ) {
        fireEvent( "preLoad", { id = id, metadata = variables._meta } );
        var data = retrieveQuery()
            .select( arrayMap( structKeyArray( variables._attributes ), function( key ) {
                return retrieveColumnForAlias( key );
            } ) )
            .addSelect( variables._key )
            .from( variables._table )
            .find( id, variables._key, variables._queryOptions );
        if ( structIsEmpty( data ) ) {
            return;
        }
        return tap( loadEntity( data ), function( entity ) {
            fireEvent( "postLoad", { entity = entity } );
        } );
    }

    private function loadEntity( data ) {
        return newEntity()
            .assignAttributesData( data )
            .assignOriginalAttributes( data )
            .set_Loaded( true );
    }

    function findOrFail( id ) {
        var entity = variables.find( id );
        if ( isNull( entity ) ) {
            throw(
                type = "EntityNotFound",
                message = "No [#variables._entityName#] found with id [#id#]"
            );
        }
        return entity;
    }

    function firstOrFail() {
        var attributes = retrieveQuery().first( options = variables._queryOptions );
        if ( structIsEmpty( attributes ) ) {
            throw(
                type = "EntityNotFound",
                message = "No [#variables._entityName#] found with constraints [#serializeJSON( retrieveQuery().getBindings() )#]"
            );
        }
        return newEntity()
            .assignAttributesData( attributes )
            .assignOriginalAttributes( attributes )
            .set_Loaded( true );
    }

    function newEntity() {
        return variables._wirebox.getInstance( variables._fullName );
    }

    function fresh() {
        return variables.find( keyValue() );
    }

    function refresh() {
        variables._relationshipsData = {};
        assignAttributesData(
            newQuery()
                .from( variables._table )
                .find( keyValue(), variables._key, variables._queryOptions )
        );
        return this;
    }

    /*===========================================
    =            Persistence Methods            =
    ===========================================*/

    function save() {
        guardReadOnly();
        fireEvent( "preSave", { entity = this } );
        if ( variables._loaded ) {
            fireEvent( "preUpdate", { entity = this } );
            guardValid();
            newQuery()
                .where( variables._key, keyValue() )
                .update( retrieveAttributesData( withoutKey = true ).map( function( key, value, attributes ) {
                    if ( isNull( value ) || isNullValue( key, value ) ) {
                        return { value = "", nulls = true, null = true };
                    }
                    if ( attributeHasSqlType( key ) ) {
                        return { value = value, cfsqltype = getSqlTypeForAttribute( key ) };
                    }
                    return value;
                } ), variables._queryOptions );
            assignOriginalAttributes( retrieveAttributesData() );
            variables._loaded = true;
            fireEvent( "postUpdate", { entity = this } );
        }
        else {
            variables._keyType.preInsert( this );
            fireEvent( "preInsert", { entity = this } );
            guardValid();
            var result = newQuery().insert( retrieveAttributesData().map( function( key, value, attributes ) {
                if ( isNull( value ) || isNullValue( key, value ) ) {
                    return { value = "", nulls = true, null = true };
                }
                if ( attributeHasSqlType( key ) ) {
                    return { value = value, cfsqltype = getSqlTypeForAttribute( key ) };
                }
                return value;
            } ), variables._queryOptions );
            variables._keyType.postInsert( this, result );
            assignOriginalAttributes( retrieveAttributesData() );
            variables._loaded = true;
            fireEvent( "postInsert", { entity = this } );
        }
        fireEvent( "postSave", { entity = this } );

        return this;
    }

    function delete() {
        guardReadOnly();
        fireEvent( "preDelete", { entity = this } );
        newQuery().delete( keyValue(), variables._key, variables._queryOptions );
        variables._loaded = false;
        fireEvent( "postDelete", { entity = this } );
        return this;
    }

    function update( attributes = {} ) {
        fill( attributes );
        return save();
    }

    function create( attributes = {} ) {
        return newEntity().assignAttributesData( attributes ).save();
    }

    function updateAll( attributes = {} ) {
        guardReadOnly();
        guardAgainstReadOnlyAttributes( attributes );
        return retrieveQuery().update( attributes, variables._queryOptions );
    }

    function deleteAll( ids = [] ) {
        guardReadOnly();
        if ( ! arrayIsEmpty( ids ) ) {
            retrieveQuery().whereIn( variables._key, ids );
        }
        return retrieveQuery().delete( options = variables._queryOptions );
    }

    /*=====================================
    =            Relationships            =
    =====================================*/

    function hasRelationship( name ) {
        var md = variables._meta;
        param md.functions = [];
        return ! arrayIsEmpty( arrayFilter( md.functions, function( func ) {
            return compareNoCase( func.name, name ) == 0;
        } ) ) || variables.relationships.keyExists( name );
    }

    function isRelationshipLoaded( name ) {
        return structKeyExists( variables._relationshipsData, name );
    }

    function retrieveRelationship( name ) {
        return variables._relationshipsData[ name ];
    }

    function assignRelationship( name, value ) {
        if ( ! isNull( value ) ) {
            variables._relationshipsData[ name ] = value;
        }
        return this;
    }

    function clearRelationships() {
        variables._relationshipsData = {};
        return this;
    }

    function clearRelationship( name ) {
        variables._relationshipsData.delete( name );
        return this;
    }

    private function belongsTo( relationName, foreignKey, ownerKey, relationMethodName ) {
        var related = variables._wirebox.getInstance( relationName );

        if ( isNull( arguments.foreignKey ) ) {
            arguments.foreignKey = related.get_EntityName() & related.get_Key();
        }
        if ( isNull( arguments.ownerKey ) ) {
            arguments.ownerKey = related.get_Key();
        }
        if ( isNull( arguments.relationMethodName ) ) {
            arguments.relationMethodName = lcase( callStackGet()[ 2 ][ "Function" ] );
        }
        return variables._wirebox.getInstance( name = "BelongsTo@quick", initArguments = {
            related = related,
            relationName = relationName,
            relationMethodName = relationMethodName,
            parent = this,
            foreignKey = foreignKey,
            ownerKey = ownerKey
        } );
    }

    private function hasOne( relationName, foreignKey, localKey ) {
        var related = variables._wirebox.getInstance( relationName );
        if ( isNull( arguments.foreignKey ) ) {
            arguments.foreignKey = variables._entityName & variables._key;
        }
        if ( isNull( arguments.localKey ) ) {
            arguments.localKey = variables._key;
        }
        return variables._wirebox.getInstance( name = "HasOne@quick", initArguments = {
            related = related,
            relationName = relationName,
            relationMethodName = lcase( callStackGet()[ 2 ][ "Function" ] ),
            parent = this,
            foreignKey = foreignKey,
            localKey = localKey
        } );
    }

    private function hasMany( relationName, foreignKey, localKey ) {
        var related = variables._wirebox.getInstance( relationName );
        if ( isNull( arguments.foreignKey ) ) {
            arguments.foreignKey = variables._entityName & variables._key;
        }
        if ( isNull( arguments.localKey ) ) {
            arguments.localKey = variables._key;
        }
        return variables._wirebox.getInstance( name = "HasMany@quick", initArguments = {
            related = related,
            relationName = relationName,
            relationMethodName = lcase( callStackGet()[ 2 ][ "Function" ] ),
            parent = this,
            foreignKey = foreignKey,
            localKey = localKey
        } );
    }

    private function belongsToMany(
        relationName,
        table,
        foreignPivotKey,
        relatedPivotKey,
        parentKey,
        relatedKey,
        relationMethodName
    ) {
        var related = variables._wirebox.getInstance( relationName );
        if ( isNull( arguments.table ) ) {
            if ( compareNoCase( related.get_Table(), variables._table ) < 0 ) {
                arguments.table = lcase( "#related.get_Table()#_#variables._table#" );
            }
            else {
                arguments.table = lcase( "#variables._table#_#related.get_Table()#" );
            }
        }
        if ( isNull( arguments.foreignPivotKey ) ) {
            arguments.foreignPivotKey = variables._entityName & variables._key;
        }
        if ( isNull( arguments.relatedPivotKey ) ) {
            arguments.relatedPivotKey = related.get_entityName() & related.get_key();
        }
        if ( isNull( arguments.relationMethodName ) ) {
            arguments.relationMethodName = lcase( callStackGet()[ 2 ][ "Function" ] );
        }
        if ( isNull( arguments.parentKey ) ) {
            arguments.parentKey = variables._key;
        }
        if ( isNull( arguments.relatedKey ) ) {
            arguments.relatedKey = related.get_key();
        }
        return variables._wirebox.getInstance( name = "BelongsToMany@quick", initArguments = {
            related = related,
            relationName = relationName,
            relationMethodName = relationMethodName,
            parent = this,
            table = arguments.table,
            foreignPivotKey = foreignPivotKey,
            relatedPivotKey = relatedPivotKey,
            parentKey = parentKey,
            relatedKey = relatedKey
        } );
    }

    private function hasManyThrough( relationName, intermediateName, firstKey, secondKey, localKey, secondLocalKey ) {
        var related = variables._wirebox.getInstance( relationName );
        var intermediate = variables._wirebox.getInstance( intermediateName );
        if ( isNull( arguments.firstKey ) ) {
            arguments.firstKey = intermediate.get_EntityName() & intermediate.get_Key();
        }
        if ( isNull( arguments.firstKey ) ) {
            arguments.firstKey = variables._entityName & variables._key;
        }
        if ( isNull( arguments.secondKey ) ) {
            arguments.secondKey = intermediate.get_entityName() & intermediate.get_key();
        }
        if ( isNull( arguments.localKey ) ) {
            arguments.localKey = variables._key;
        }
        if ( isNull( arguments.secondLocalKey ) ) {
            arguments.secondLocalKey = intermediate.get_key();
        }

        return variables._wirebox.getInstance( name = "HasManyThrough@quick", initArguments = {
            related = related,
            relationName = relationName,
            relationMethodName = lcase( callStackGet()[ 2 ][ "Function" ] ),
            parent = this,
            intermediate = intermediate,
            firstKey = firstKey,
            secondKey = secondKey,
            localKey = localKey,
            secondLocalKey = secondLocalKey
        } );
    }

    private function polymorphicHasMany( required relationName, required name, type, id, localKey ) {
        var related = variables._wirebox.getInstance( relationName );

        if ( isNull( arguments.type ) ) {
            arguments.type = arguments.name & "_type";
        }
        if ( isNull( arguments.id ) ) {
            arguments.id = arguments.name & "_id";
        }
        var table = related.get_table();
        if ( isNull( arguments.localKey ) ) {
            arguments.localKey = variables._key;
        }

        return variables._wirebox.getInstance( name = "PolymorphicHasMany@quick", initArguments = {
            related = related,
            relationName = relationName,
            relationMethodName = lcase( callStackGet()[ 2 ][ "Function" ] ),
            parent = this,
            type = type,
            id = id,
            localKey = localKey
        } );
    }

    private function polymorphicBelongsTo( name, type, id, ownerKey ) {
        if ( isNull( arguments.name ) ) {
            arguments.name = lcase( callStackGet()[ 2 ][ "Function" ] );
        }
        if ( isNull( arguments.type ) ) {
            arguments.type = arguments.name & "_type";
        }
        if ( isNull( arguments.id ) ) {
            arguments.id = arguments.name & "_id";
        }
        var relationName = retrieveAttribute( arguments.type, "" );
        if ( relationName == "" ) {
            return variables._wirebox.getInstance( name = "PolymorphicBelongsTo@quick", initArguments = {
                related = this.set_EagerLoad( [] ).resetQuery(),
                relationName = relationName,
                relationMethodName = name,
                parent = this,
                foreignKey = arguments.id,
                ownerKey = "",
                type = type
            } );
        }
        var related = variables._wirebox.getInstance( relationName );
        if ( isNull( ownerKey ) ) {
            arguments.ownerKey = related.get_key();
        }
        return variables._wirebox.getInstance( name = "PolymorphicBelongsTo@quick", initArguments = {
            related = related,
            relationName = relationName,
            relationMethodName = name,
            parent = this,
            foreignKey = arguments.id,
            ownerKey = ownerKey,
            type = type
        } );
    }

    function with( relationName ) {
        if ( isSimpleValue( relationName ) && relationName == "" ) {
            return this;
        }
        relationName = isArray( relationName ) ? relationName : [ relationName ];
        arrayAppend( variables._eagerLoad, relationName, true );
        return this;
    }

    function eagerLoadRelations( entities ) {
        if ( arrayIsEmpty( entities ) || arrayIsEmpty( variables._eagerLoad ) ) {
            return entities;
        }

        arrayEach( variables._eagerLoad, function( relationName ) {
            entities = eagerLoadRelation( relationName, entities );
        } );

        return entities;
    }

    private function eagerLoadRelation( relationName, entities ) {
        var relation = invoke( this, relationName ).resetQuery();
        relation.addEagerConstraints( entities );
        return relation.match(
            relation.initRelation( entities, relationName ),
            relation.getEager(),
            relationName
        );
    }

    /*=======================================
    =            QB Utilities            =
    =======================================*/

    public function resetQuery() {
        newQuery();
        return this;
    }

    public function newQuery() {
        if ( variables._meta.keyExists( "grammar" ) ) {
            variables._builder.setGrammar(
                variables._wirebox.getInstance( variables._meta.grammar & "@qb" )
            );
        }
        variables.query = variables._builder.newQuery()
            .setReturnFormat( "array" )
            .from( variables._table );
        return variables.query;
    }

    public function retrieveQuery() {
        if ( ! structKeyExists( variables, "query" ) ) {
            variables.query = newQuery();
        }
        return variables.query;
    }

    /*=====================================
    =            Magic Methods            =
    =====================================*/

    function onMissingMethod( missingMethodName, missingMethodArguments ) {
        var columnValue = tryColumnName( missingMethodName, missingMethodArguments );
        if ( ! isNull( columnValue ) ) { return columnValue; }
        var q = tryScopes( missingMethodName, missingMethodArguments );
        if ( ! isNull( q ) ) {
            variables.query = q.retrieveQuery();
            return this;
        }
        var r = tryRelationships( missingMethodName, missingMethodArguments );
        if ( ! isNull( r ) ) { return r; }
        return forwardToQB( missingMethodName, missingMethodArguments );
    }

    private function tryColumnName( missingMethodName, missingMethodArguments ) {
        var getColumnValue = tryColumnGetters( missingMethodName );
        if ( ! isNull( getColumnValue ) ) { return getColumnValue; }
        var setColumnValue = tryColumnSetters( missingMethodName, missingMethodArguments );
        if ( ! isNull( setColumnValue ) ) { return this; }
        return;
    }

    private function tryColumnGetters( missingMethodName ) {
        if ( ! variables._str.startsWith( missingMethodName, "get" ) ) {
            return;
        }

        var columnName = variables._str.slice( missingMethodName, 4 );

        if ( isColumnAlias( columnName ) ) {
            return retrieveAttribute( retrieveColumnForAlias( columnName ) );
        }

        if ( hasAttribute( columnName ) ) {
            return retrieveAttribute( columnName );
        }

        return;
    }

    private function tryColumnSetters( missingMethodName, missingMethodArguments ) {
        if ( ! variables._str.startsWith( missingMethodName, "set" ) ) {
            return;
        }

        var columnName = variables._str.slice( missingMethodName, 4 );
        assignAttribute( columnName, missingMethodArguments[ 1 ] );
        return missingMethodArguments[ 1 ];
    }

    private function tryRelationships( missingMethodName, missingMethodArguments ) {
        var relationship = tryRelationshipGetter( missingMethodName, missingMethodArguments );
        if ( ! isNull( relationship ) ) { return relationship; }
        return tryRelationshipDefinition( missingMethodName );
    }

    private function tryRelationshipGetter( missingMethodName, missingMethodArguments ) {
        if ( ! variables._str.startsWith( missingMethodName, "get" ) ) {
            return;
        }

        var relationshipName = variables._str.slice( missingMethodName, 4 );

        if ( ! hasRelationship( relationshipName ) ) {
            return;
        }

        if ( ! isRelationshipLoaded( relationshipName ) ) {
            var relationship = "";
            if ( variables.relationships.keyExists( relationshipName ) ) {
                var method = variables.relationships[ relationshipName ];
                relationship = method( missingMethodArguments );
            }
            else {
                relationship = invoke( this, relationshipName, missingMethodArguments );
            }
            relationship.setRelationMethodName( relationshipName );
            assignRelationship( relationshipName, relationship.getResults() );
        }

        return retrieveRelationship( relationshipName );
    }

    private function tryRelationshipDefinition( relationshipName ) {
        if ( variables.relationships.keyExists( relationshipName ) ) {
            var method = variables.relationships[ relationshipName ];
            var relationship = method();
            relationship.setRelationMethodName( relationshipName );
            return relationship;
        }
    }

    private function tryScopes( missingMethodName, missingMethodArguments ) {
        if ( structKeyExists( variables, "scope#missingMethodName#" ) ) {
            return invoke( this, "scope#missingMethodName#", {
                query = this,
                args = missingMethodArguments
            } );
        }
        return;
    }

    private function forwardToQB( missingMethodName, missingMethodArguments ) {
        var result = invoke( retrieveQuery(), missingMethodName, missingMethodArguments );
        if ( isSimpleValue( result ) ) {
            return result;
        }
        return this;
    }

    function getMemento() {
        return variables._attributes.keyArray().reduce( function( acc, key ) {
            acc[ key ] = retrieveAttribute( key );
            return acc;
        }, {} );
    }

    function $renderdata() {
        return getMemento();
    }

    /*=======================================
    =            Other Utilities            =
    =======================================*/

    private function tap( value, callback ) {
        callback( value );
        return value;
    }

    private function metadataInspection() {
        var md = getMetadata( this );
        variables._meta = md;
        param variables._key = "id";
        variables._fullName = md.fullname;
        param md.mapping = listLast( md.fullname, "." );
        variables._mapping = md.mapping;
        param md.entityName = listLast( md.name, "." );
        variables._entityName = md.entityName;
        param md.table = variables._str.plural( variables._str.snake( variables._entityName ) );
        variables._table = md.table;
        param variables._queryOptions = {};
        if ( md.keyExists( "datasource" ) ) {
            variables._queryOptions = { datasource = md.datasource };
        }
        param md.readonly = false;
        variables._readonly = md.readonly;
        param md.properties = [];
        assignAttributesFromProperties( md.properties );
    }

    private function assignAttributesFromProperties( properties ) {
        variables._attributes = properties.reduce( function( acc, prop ) {
            param prop.column = prop.name;
            param prop.persistent = true;
            param prop.nullValue = "";
            param prop.convertToNull = true;
            if ( prop.convertToNull ) {
                variables._nullValues[ prop.name ] = prop.nullValue;
            }
            if ( prop.persistent ) {
                acc[ prop.name ] = prop.column;
            }
            return acc;
        }, {} );
        return this;
    }

    private function deepEqual( required expected, required actual ) {
        // Numerics
        if (
            isNumeric( arguments.actual ) &&
            isNumeric( arguments.expected ) &&
            toString( arguments.actual ) == toString( arguments.expected )
        ) {
            return true;
        }

        // Other Simple values
        if (
            isSimpleValue( arguments.actual ) &&
            isSimpleValue( arguments.expected ) &&
            arguments.actual == arguments.expected
        ) {
            return true;
        }

        // Queries
        if ( isQuery( arguments.actual ) && isQuery( arguments.expected ) ) {
            // Check number of records
            if ( arguments.actual.recordCount != arguments.expected.recordCount ) {
                return false;
            }

            // Get both column lists and sort them the same
            var actualColumnList = listSort( arguments.actual.columnList, "textNoCase" );
            var expectedColumnList = listSort( arguments.expected.columnList, "textNoCase" );

            // Check column lists
            if ( actualColumnList != expectedColumnList ) {
                return false;
            }

            for ( var i = 1; i <= arguments.actual.recordCount; i++ ) {
                for ( var column in listToArray( actualColumnList ) ) {
                    if ( arguments.actual[ column ][ i ] != arguments.expected[ column ][ i ] ) {
                        return false;
                    }
                }
            }

            return true;
        }

        // UDFs
        if (
            isCustomFunction( arguments.actual ) &&
            isCustomFunction( arguments.expected ) &&
            arguments.actual.toString() == arguments.expected.toString()
        ) {
            return true;
        }

        // XML
        if (
            IsXmlDoc( arguments.actual ) &&
            IsXmlDoc( arguments.expected ) &&
            toString( arguments.actual ) == toString( arguments.expected )
        ) {
            return true;
        }

        // Arrays
        if ( isArray( arguments.actual ) && isArray( arguments.expected ) ) {
            if ( arrayLen( arguments.actual ) neq arrayLen( arguments.expected ) ) {
                return false;
            }

            for ( var i = 1; i <= arrayLen( arguments.actual ); i++ ) {
                if ( arrayIsDefined( arguments.actual, i ) && arrayIsDefined( arguments.expected, i ) ) {
                    // check for both nulls
                    if ( isNull( arguments.actual[ i ] ) && isNull( arguments.expected[ i ] ) ) {
                        continue;
                    }
                    // check if one is null mismatch
                    if ( isNull( arguments.actual[ i ] ) || isNull( arguments.expected[ i ] ) ) {
                        return false;
                    }
                    // And make sure they match
                    if ( ! deepEqual( arguments.actual[ i ], arguments.expected[ i ] ) ) {
                        return false;
                    }
                    continue;
                }
                // check if both not defined, then continue to next element
                if ( ! arrayIsDefined( arguments.actual, i ) && ! arrayIsDefined( arguments.expected, i ) ) {
                    continue;
                } else {
                    return false;
                }
            }

            return true;
        }

        // Structs / Object
        if ( isStruct( arguments.actual ) && isStruct( arguments.expected ) ) {

            var actualKeys = listSort( structKeyList( arguments.actual ), "textNoCase" );
            var expectedKeys = listSort( structKeyList( arguments.expected ), "textNoCase" );

            if ( actualKeys != expectedKeys ) {
                return false;
            }

            // Loop over each key
            for ( var key in arguments.actual ) {
                // check for both nulls
                if ( isNull( arguments.actual[ key ] ) && isNull( arguments.expected[ key ] ) ) {
                    continue;
                }
                // check if one is null mismatch
                if ( isNull( arguments.actual[ key ] ) || isNull( arguments.expected[ key ] ) ) {
                    return false;
                }
                // And make sure they match when actual values exist
                if ( ! deepEqual( arguments.actual[ key ], arguments.expected[ key ] ) ) {
                    return false;
                }
            }

            return true;
        }

        return false;
    }

    public struct function groupBy( required array items, required string key, boolean forceLookup = false ) {
        return items.reduce( function( acc, item ) {
            if ( ( isObject( item ) && structKeyExists( item, "get#key#" ) ) || forceLookup ) {
                var value = invoke( item, "get#key#" );
            }
            else {
                var value = item[ key ];
            }
            if ( ! structKeyExists( acc, value ) ) {
                acc[ value ] = [];
            }
            arrayAppend( acc[ value ], item );
            return acc;
        }, {} );
    }

    /*=================================
    =           Validation            =
    =================================*/

    private function guardValid() {
        if ( isNull( variables._validationManager ) ) {
            return this;
        }

        param variables._settings.automaticValidation = false;
        if ( ! variables._settings.automaticValidation ) {
            return this;
        }

        var validationResult = variables._validationManager.validate(
            target = retrieveAttributesData( aliased = true ),
            constraints = this.constraints
        );

        if ( ! validationResult.hasErrors() ) {
            return this;
        }

        throw(
            type = "InvalidEntity",
            message = "The #variables._entityName# entity failed to pass validation",
            detail = validationResult.getAllErrorsAsJson()
        );
    }

    /*=================================
    =            Read Only            =
    =================================*/

    private function guardReadOnly() {
        if ( isReadOnly() ) {
            throw(
                type = "QuickReadOnlyException",
                message = "[#variables._entityName#] is marked as a read-only entity."
            );
        }
    }

    private function isReadOnly() {
        return variables._readonly;
    }

    private function guardAgainstReadOnlyAttributes( attributes ) {
        for ( var name in arguments.attributes ) {
            guardAgainstReadOnlyAttribute( name );
        }
    }

    private function guardAgainstNonExistentAttribute( name ) {
        if ( ! hasAttribute( name ) ) {
            throw(
                type = "AttributeNotFound",
                message = "The [#name#] attribute was not found on the [#variables._entityName#] entity"
            );
        }
    }

    private function guardAgainstReadOnlyAttribute( name ) {
        if ( isReadOnlyAttribute( name ) ) {
            throw(
                type = "QuickReadOnlyException",
                message = "[#name#] is a read-only property on [#variables._entityName#]"
            );
        }
    }

    private function isReadOnlyAttribute( name ) {
        var md = variables._meta;
        if ( ! md.keyExists( "properties" ) || arrayIsEmpty( md.properties ) ) {
            return false;
        }
        var foundProperties = arrayFilter( md.properties, function( prop ) {
            return prop.name == name;
        } );
        if ( arrayIsEmpty( foundProperties ) ) {
            return false;
        }
        return foundProperties[ 1 ].keyExists( "readonly" ) && foundProperties[ 1 ].readonly;
    }

    /*==============================
    =            Events            =
    ==============================*/

    function fireEvent( eventName, eventData ) {
        eventData.entityName = variables._entityName;
        if ( eventMethodExists( eventName ) ) {
            invoke( this, eventName, { eventData = eventData } );
        }
        if ( ! isNull( variables._interceptorService ) ) {
            variables._interceptorService.processState( "quick" & eventName, eventData );
        }
    }

    private function eventMethodExists( eventName ) {
        return variables.keyExists( eventName );
    }

    private function attributeHasSqlType( name ) {
        return ! variables._meta.properties.filter( function( property ) {
            return property.name == retrieveAliasForColumn( name ) && property.keyExists( "sqltype" );
        } ).isEmpty();
    }

    private function getSqlTypeForAttribute( name ) {
        return variables._meta.properties.filter( function( property ) {
            return property.name == retrieveAliasForColumn( name );
        } )[ 1 ].sqltype;
    }

    private function isNullValue( key, value ) {
        return variables._nullValues.keyExists( retrieveAliasForColumn( key ) ) &&
            compare( variables._nullValues[ retrieveAliasForColumn( key ) ], value ) == 0;
    }

}
