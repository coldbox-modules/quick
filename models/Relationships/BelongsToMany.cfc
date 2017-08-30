component accessors="true" extends="quick.models.Relationships.BaseRelationship" {

    property name="builder" inject="provider:QueryBuilder@qb" getter="false" setter="false";
    property name="table";

    variables.defaultValue = [];

    function init( related, relationName, relationMethodName, owning, table, foreignKey, foreignKeyValue, relatedKey ) {
        setTable( arguments.table );
        super.init( related, relationName, relationMethodName, owning, foreignKey, foreignKeyValue, relatedKey );
        return this;
    }

    function apply() {
        getRelated().join( getTable(), function( j ) {
            j.on(
                "#getRelated().getTable()#.#getRelated().getKey()#",
                "#getTable()#.#getOwningKey()#"
            );
            j.where( "#getTable()#.#getForeignKey()#", getForeignKeyValue() );
        } );
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
            return id.getKeyValue();
        } );

        builder.get().from( getTable() ).insert( arrayMap( arguments.ids, function( id ) {
            return {
                "#getForeignKey()#" = getForeignKeyValue(),
                "#getOwningKey()#" = id
            };
        } ) );

        getOwning().clearRelationship( getRelationMethodName() );

        return this;
    }

    function detatch( ids ) {
        if ( ! isArray( arguments.ids ) ) {
            arguments.ids = [ arguments.ids ];
        }

        arguments.ids = arrayMap( arguments.ids, function( id ) {
            if ( isSimpleValue( id ) ) {
                return id;
            }
            return id.getKeyValue();
        } );

        builder.get()
            .from( getTable() )
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
            return id.getKeyValue();
        } );

        builder.get()
            .from( getTable() )
            .where( getForeignKey(), getForeignKeyValue() )
            .delete();

        attach( arguments.ids );

        return this;
    }

}