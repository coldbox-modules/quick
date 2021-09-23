component {

    function up( sb, qb ) {
        sb.create( "children", function( t ) {
            t.increments( "childID" );
            t.unsignedInteger( "familyID" );
            t.string( "firstname" );
            t.string( "lastname" );
        } );
        
        qb.table( "children" ).insert( [
            {
                "childID": 1,
                "familyID": 1,
                "firstName": "River",
                "lastName": "Song"
            }
        ] );
    }

    function down( sb, qb ) {
        sb.drop( "children" );
    }

}
