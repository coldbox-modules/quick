component {

    function up( sb, qb ) {
        sb.create( "tags", function( t ) {
            t.increments( "id" );
            t.string( "name" );
        } );

        qb.table( "tags" ).insert( [
            { "id": 1, "name": "programming" },
            { "id": 2, "name": "music" }
        ] );
    }

    function down( sb, qb ) {
        sb.drop( "tags" );
    }

}
