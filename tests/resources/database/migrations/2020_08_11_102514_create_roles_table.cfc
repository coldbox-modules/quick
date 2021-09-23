component {

    function up( sb, qb ) {
        sb.create( "roles", function( t ) {
            t.increments( "id" );
            t.string( "name" );
        } );

        qb.table( "roles" ).insert( [
            {
                "id": 1,
                "name": "ADMIN"
            },
            {
                "id": 2,
                "name": "MODERATOR"
            },
            {
                "id": 3,
                "name": "USER"
            }
        ] );
    }

    function down( sb, qb ) {
        sb.drop( "roles" );
    }

}
