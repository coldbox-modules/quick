component extends="quick.models.Relationships.HasOneOrMany" {

    function init( related, relationName, relationMethodName, parent, type, id, localKey ) {
        variables.morphType = arguments.type;
        variables.morphClass = arguments.parent.get_entityName();
        return super.init( related, relationName, relationMethodName, parent, id, localKey );
    }

    function addConstraints() {
        super.addConstraints();
        variables.related.where( variables.morphType, variables.morphClass );
    }

    function addEagerConstraints( entities ) {
        super.addEagerConstraints( entities );
        variables.related.where( variables.morphType, variables.morphClass );
    }

}
