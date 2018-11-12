component extends="cfcollection.models.Collection" {

    function collect( data ) {
        return new QuickCollection( data );
    }

    function load( relationName ) {
        if ( this.empty() ) {
            return this;
        }

        if ( ! isArray( relationName ) ) {
            relationName = [ relationName ];
        }

        for ( var relation in relationName ) {
            eagerLoadRelation( relation );
        }

        return this;
    }

    function getMemento() {
        return this.map( function( entity ) {
            return entity.$renderData();
        } ).get();
    }

    function $renderData() {
        return getMemento();
    }

    private function eagerLoadRelation( relationName ) {
        var relation = invoke( get( 1 ), relationName ).resetQuery();
        relation.addEagerConstraints( get() );
        variables.collection = relation.match(
            relation.initRelation( get(), relationName ),
            relation.getEager(),
            relationName
        );
    }

}
