component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe( "HasManyThrough subselect alias bug regression", function() {
			it( "uses the correct alias for parent table in subselects (no raw table name)", function() {
				// Setup tables and data as in the bug report
				getInstance( "A" ).initTable();
				getInstance( "B" ).initTable();
				getInstance( "C" ).initTable();
				getInstance( "D" ).initTable();

				queryExecute( """
					insert into rmme_d(dID, dValue) values (42, 'some value in table D');
					insert into rmme_a (aID) values (1);
					insert into rmme_b (bID, aID) values (2, 1);
					insert into rmme_c (cID, bID, dID) values (3, 2, 42);
				""" );

				// This should not throw: The multi-part identifier "rmme_C.dID" could not be bound.
				var v = getInstance( "A" ).asMemento( includes = [ "Cs" ] ).get();
				expect( v ).notToBeNull();
				expect( v[ 1 ][ "Cs" ] ).notToBeNull();
				expect( v[ 1 ][ "Cs" ][ 1 ][ "inlined_dValue" ] ).toBe( "some value in table D" );
			} );
		} );
	}

}
