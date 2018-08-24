component accessors="true" extends="quick.models.Relationships.BaseRelationship" {

    property name="builder" inject="provider:QueryBuilder@qb" getter="false" setter="false";
    property name="table";

    variables.defaultValue = [];

    function init( wirebox, related, relationName, relationMethodName, owning, table, foreignKey, foreignKeyValue, relatedKey ) {
        setTable( arguments.table );
        super.init( wirebox, related, relationName, relationMethodName, owning, foreignKey, foreignKeyValue, relatedKey );
        return this;
    }

    function onDIComplete() {
        setDefaultValue( collect() );
    }

    function apply() {
        getRelated().join( variables.table, function( j ) {
            j.on(
                "#getRelated().get_Table()#.#getRelated().get_Key()#",
                "#variables.table#.#getOwningKey()#"
            );
            j.where( "#variables.table#.#getForeignKey()#", getForeignKeyValue() );
        } );
    }

    function fromGroup( items ) {
        return collect( items );
    }

    function retrieve() {
        return getRelated().get();
    }

    function attach( ids ) {
        if ( ! isArray( arguments.ids ) ) {
            arguments.ids = [ arguments.ids ];
        }

        arguments.ids = arrayMap( arguments.ids, function( id ) {
            if ( isSimpleValue( id ) ) {
                return id;
            }
            return id.keyValue();
        } );

        builder.get().from( variables.table ).insert( arrayMap( arguments.ids, function( id ) {
            return {
                "#getForeignKey()#" = getForeignKeyValue(),
                "#getOwningKey()#" = id
            };
        } ) );

        getOwning().clearRelationship( getRelationMethodName() );

        return this;
    }

    function detach( ids ) {
        if ( ! isArray( arguments.ids ) ) {
            arguments.ids = [ arguments.ids ];
        }

        arguments.ids = arrayMap( arguments.ids, function( id ) {
            if ( isSimpleValue( id ) ) {
                return id;
            }
            return id.keyValue();
        } );

        builder.get()
            .from( variables.table )
            .where( getForeignKey(), getForeignKeyValue() )
            .whereIn( getOwningKey(), arguments.ids )
            .delete();

        getOwning().clearRelationship( getRelationMethodName() );

        return this;
    }

    function sync( ids ) {
        if ( ! isArray( arguments.ids ) ) {
            arguments.ids = [ arguments.ids ];
        }

        arguments.ids = arrayMap( arguments.ids, function( id ) {
            if ( isSimpleValue( id ) ) {
                return id;
            }
            return id.keyValue();
        } );

        builder.get()
            .from( variables.table )
            .where( getForeignKey(), getForeignKeyValue() )
            .delete();

        attach( arguments.ids );

        return this;
    }

}
