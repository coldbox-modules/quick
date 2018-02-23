component extends="quick.models.Relationships.BaseRelationship" {

    function onDIComplete() {
        setDefaultValue( javacast( "null", "" ) );
    }

    function apply() {
        getRelated().where( getForeignKey(), getForeignKeyValue() );
    }

    function fromGroup( items ) {
        return items[ 1 ];
    }

    function retrieve() {
        return getRelated().first();
    }

}
