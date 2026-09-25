component extends="coldbox.system.EventHandler" {

	// The process environment fixes the fault before boot. This authenticated
	// endpoint can start it once; request input cannot select or alter it.
	function start( event, rc, prc ) {
		if ( application.soakFaultMode == "none" ) {
			event.renderData(
				type       = "json",
				data       = { "error" : "Faults disabled" },
				statusCode = 404
			);
			return;
		}
		lock name="quick-soak-fault-start" type="exclusive" timeout=5 {
			if ( application.soakFaultStarted != 0 ) {
				event.renderData(
					type       = "json",
					data       = { "error" : "Fault already started" },
					statusCode = 409
				);
				return;
			}
			application.soakFaultStarted = getTickCount();
			if ( application.soakFaultMode == "held-connection" ) {
				// Deliberately borrow outside request-managed release. These engine APIs
				// are specific to the pinned Lucee diagnostic profile. One real pool
				// connection is retained; no long-running query or CFML thread is added.
				var datasource = getPageContext().getApplicationContext().getDataSource( "quick_soak" );
				var pool       = getPageContext()
					.getConfig()
					.getDatasourceConnectionPool(
						datasource,
						datasource.getUsername(),
						datasource.getPassword()
					);
				var borrowed = pool.borrowObject();
				try {
					var statement = borrowed.getConnection().createStatement();
					try {
						var result = statement.executeQuery( "SELECT 1" );
						try {
							if ( !result.next() || result.getInt( 1 ) != 1 ) {
								throw( type = "SoakFaultSetup", message = "Borrowed connection validation failed" );
							}
						} finally {
							result.close();
						}
					} finally {
						statement.close();
					}
					application.soakHeldConnection = borrowed;
				} catch ( any error ) {
					borrowed.release();
					rethrow;
				}
			}
		}
		event.renderData(
			type = "json",
			data = {
				"mode"    : application.soakFaultMode,
				"started" : true
			}
		);
	}

}
