component extends="quick.models.Relationships.BaseRelationship" {

    function init( related, foreignKey, foreignKeyValue ) {
        variables.related = arguments.related;
        related.where( foreignKey, foreignKeyValue );
        return this;
    }

    function retrieve() {
        return related.get();
    }

}