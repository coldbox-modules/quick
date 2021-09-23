component {

    function up( sb, qb ) {
        sb.create( "b", function( t ) {
            t.increments( "id" );
            t.unsignedInteger( "a_id" ).nullable();
            t.string( "name" );
        } );
    }

    function down( sb, qb ) {
        sb.drop( "b" );
    }

}
