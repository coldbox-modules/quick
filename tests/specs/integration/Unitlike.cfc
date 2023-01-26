component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

	function run() {
		describe( "codegen", function() {
			it( "Nested wheres have the expected associativity", function() {
                var sql = getInstance( "User" )
                    .reselect("*")
                    .withNestedWheresCombinedViaOr()
                    .toSql();

                expect(sql).toBe("SELECT * FROM `users` WHERE ((`users`.`first_name` = ? AND `users`.`last_name` = ?) OR (`users`.`first_name` = ? AND `users`.`last_name` = ?))")
			} );
		} );
	}

}
