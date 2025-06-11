component {

	function up( schema, qb ) {
		schema.create( "HasManyDeepKeyTest_A", function( t ) {
			t.string( "aID", 8 ).primaryKey()
		} );

		schema.create( "HasManyDeepKeyTest_B", function( t ) {
			t.string( "aID", 8 )
			t.string( "bID", 8 ).primaryKey()
			t.string( "cKey1" )
			t.string( "cKey2" )
		} );
		schema.create( "HasManyDeepKeyTest_C", function( t ) {
			t.string( "cKey1" )
			t.string( "cKey2" )
		} );

		qb.newQuery()
			.from( "HasManyDeepKeyTest_A" )
			.insert( [ { "aID" : "a1" } ] );

		qb.newQuery()
			.from( "HasManyDeepKeyTest_B" )
			.insert( {
				// match a1->b1->(c1k1,c1k2)
				"aID"   : "a1",
				"bID"   : "b1",
				"cKey1" : "c1k1",
				"cKey2" : "c1k2"
			} );

		qb.newQuery()
			.from( "HasManyDeepKeyTest_B" )
			.insert( {
				// match a1->b1->(c1k1,c1k2)
				"aID"   : "a1",
				"bID"   : "b2",
				"cKey1" : "c1k1",
				"cKey2" : "c1k2"
			} );

		qb.newQuery()
			.from( "HasManyDeepKeyTest_B" )
			.insert( {
				// will not match anything (wrong composite key to C)
				"aID"   : "a1",
				"bID"   : "b3",
				"cKey1" : "c2k1",
				"cKey2" : "c2k2"
			} );

		qb.newQuery()
			.from( "HasManyDeepKeyTest_B" )
			.insert( {
				// will not match anything (wrong aID)
				"aID"   : "a2",
				"bID"   : "b4",
				"cKey1" : "c1k1",
				"cKey2" : "c1k2"
			} );

		qb.newQuery()
			.from( "HasManyDeepKeyTest_C" )
			.insert( { "cKey1" : "c1k1", "cKey2" : "c1k2" } );
	}

	function down( schema, qb ) {
		schema.drop( "HasManyDeepKeyTest_C" );
		schema.drop( "HasManyDeepKeyTest_B" );
		schema.drop( "HasManyDeepKeyTest_A" );
	}

}
