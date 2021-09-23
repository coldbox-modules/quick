component {

    function up( sb, qb ) {
        sb.create( "externalThings", function( t ) {
            t.increments( "thingId" );
            t.unsignedInteger( "userId" );
            t.string( "externalId" );
            t.string( "value" ).nullable();
        } );
    }

    function down( sb, qb ) {
        sb.drop( "externalThings" );
    }

}
