component extends="quick.models.Relationships.BaseRelationship" {

    function onDIComplete() {
        setDefaultValue( javacast( "null", "" ) );
    }

    function apply() {
        getRelated().where( getForeignKey(), getForeignKeyValue() );
    }

    function retrieve() {
        return getRelated().first();
    }

}
