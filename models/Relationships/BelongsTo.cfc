component extends="quick.models.Relationships.BaseRelationship" {

    function init( related, foreignKeyValue ) {
        variables.related = arguments.related;
        variables.foreignKeyValue = arguments.foreignKeyValue;

        return this;
    }

    function retrieve() {
        return related.first();
    }

}