component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe( "Aliased Composite Key Spec", function() {
			it( "supports physical column names in a composite key with aliased properties", function() {
				var composite = getInstance( "AliasedComposite" ).findOrFail( [ 1, 2 ] );

				expect( composite.getGroupId() ).toBe( 1 );
				expect( composite.getMemberId() ).toBe( 2 );
				expect( composite.keyNames() ).toBe( [ "a", "b" ] );
				expect( composite.keyValues() ).toBe( [ 1, 2 ] );
				expect( composite.getMemento() ).toBe( { "groupId" : 1, "memberId" : 2 } );
			} );
		} );
	}

}
