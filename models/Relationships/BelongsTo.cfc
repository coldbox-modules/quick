component extends="quick.models.Relationships.BaseRelationship" {

    variables.defaultValue = [];

    function retrieve() {
        return related.first();
    }

}