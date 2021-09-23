component {

    function up( sb, qb ) {
        sb.create( "a", function( t ) {
            t.increments( "id" );
            t.string( "name" );
        } );
    }

    function down( sb, qb ) {
        sb.drop( "a" );
    }

}
