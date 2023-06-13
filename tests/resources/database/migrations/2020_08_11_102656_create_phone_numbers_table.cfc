component {

	function up( schema, qb ) {
		schema.create( "phone_numbers", function( t ) {
			t.increments( "id" );
			t.string( "number" );
			t.boolean( "active" );
			t.boolean( "confirmed" ).nullable();
		} );

		qb.table( "phone_numbers" )
			.insert( [
				{
					"id"        : 1,
					"number"    : "323-232-3232",
					"active"    : 1,
					"confirmed" : 1
				},
				{
					"id"        : 2,
					"number"    : "545-454-5454",
					"active"    : 0,
					"confirmed" : 0
				},
				{
					"id"        : 3,
					"number"    : "878-787-8787",
					"active"    : 1,
					"confirmed" : { "value" : "", "null" : true }
				}
			] );
	}

	function down( schema, qb ) {
		schema.drop( "phone_numbers" );
	}

}
