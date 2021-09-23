component {

    function up( sb, qb ) {
        sb.create( "games", function( t ) {
            t.increments( "ID" );
            t.unsignedInteger( "fieldID" ).nullable();
            t.unsignedInteger( "clientID" ).nullable();
        } );

        qb.table( "games" ).insert( [
            {
                "ID": 1,
                "fieldID": 1,
                "clientID": 2
            }
        ] );
    }

    function down( sb, qb ) {
        sb.drop( "games" );
    }

}
