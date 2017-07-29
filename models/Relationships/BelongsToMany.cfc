component accessors="true" extends="quick.models.Relationships.BaseRelationship" {

    property name="table";

    variables.defaultValue = [];

    function init( related, table, foreignKey, foreignKeyValue, relatedKey ) {
        super.init( related, foreignKey, foreignKeyValue, relatedKey );
        setTable( arguments.table );
        return this;
    }

    function retrieve() {
        return related.join( getTable(), function( j ) {
            j.on(
                "#getRelated().getTable()#.#getRelated().getKey()#",
                "#getTable()#.#getOwningKey()#"
            );
            j.where( "#getTable()#.#getForeignKey()#", getForeignKeyValue() );
        } ).get();
    }

}