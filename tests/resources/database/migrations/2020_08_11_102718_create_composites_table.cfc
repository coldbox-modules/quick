component {

    function up( sb, qb ) {
        sb.create( "composites", function( t ) {
            t.unsignedInteger( "a" );
            t.unsignedInteger( "b" );
            t.primaryKey( [ "a", "b" ] );
        } );

        qb.table( "composites" ).insert( [
            { "a": 1, "b": 1 },
            { "a": 1, "b": 2 }
        ] );
    }

    function down( sb, qb ) {
        sb.drop( "composites" );
    }

}
