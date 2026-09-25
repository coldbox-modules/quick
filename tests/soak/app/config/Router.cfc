component {

	function configure() {
		route( "/health/ready" ).to( "Api.ready" );
		route( "/diagnostics" ).to( "Api.diagnostics" );
		route( "/api/users/lookup" ).to( "Api.lookup" );
		route( "/api/users/:id/posts/:postId" ).to( "Api.relatedPost" );
		route( "/api/users/:id" ).to( "Api.user" );
		route( "/api/users" ).to( "Api.users" );
		route( "/api/reports/posts" ).to( "Api.report" );
		route( "/api/query-variants/:variant" ).to( "Api.variant" );
		route( "/api/transactions/rollback" ).to( "Api.rollback" );
		route( "/api/scratch/:token" ).to( "Api.scratch" );
		route( "/api/posts/:id" )
			.withHandler( "Api" )
			.toAction( {
				GET    : "post",
				PATCH  : "updatePost",
				DELETE : "deletePost"
			} );
		route( "/api/posts" ).withHandler( "Api" ).toAction( { GET : "posts", POST : "createPost" } );
	}

}
