component {

    this.name = "ColdBoxTestingSuite" & hash(getCurrentTemplatePath());
    this.sessionManagement  = true;
    this.setClientCookies   = true;
    this.sessionTimeout     = createTimeSpan( 0, 0, 15, 0 );
    this.applicationTimeout = createTimeSpan( 0, 0, 15, 0 );

    testsPath = getDirectoryFromPath( getCurrentTemplatePath() );
    this.mappings[ "/tests" ] = testsPath;
    rootPath = REReplaceNoCase( this.mappings[ "/tests" ], "tests(\\|/)", "" );
    this.mappings[ "/root" ] = rootPath;
    this.mappings[ "/testingModuleRoot" ] = listDeleteAt( rootPath, listLen( rootPath, '\/' ), "\/" );
    this.mappings[ "/quick" ] = listDeleteAt( rootPath, listLen( rootPath, '\/' ), "\/" );
    this.mappings[ "/app" ] = testsPath & "resources/app";
    this.mappings[ "/coldbox" ] = testsPath & "resources/app/coldbox";
    this.mappings[ "/testbox" ] = rootPath & "/testbox";

    if ( server.keyExists( "lucee" ) ) {
        this.datasources[ "quick" ] = {
            driver = "other",
            class = "org.h2.Driver",
            connectionString = "jdbc:h2:mem:;MODE=MySQL",
            username = "sa"
        };    
    }
    else {
        this.datasources[ "quick" ] = {
            driver = "other",
            class = "org.h2.Driver",
            url = "jdbc:h2:mem:;MODE=MySQL",
            username = "sa"
        };
    }

    this.datasource = "quick";

    function onRequestStart() {
        // applicationStop();
        setUpDatabase();
    }

    private function setUpDatabase() {
        queryExecute( "DROP ALL OBJECTS" );
        queryExecute( "
            CREATE TABLE `countries` (
              `id` int(11) NOT NULL AUTO_INCREMENT,
              `name` varchar(50) NOT NULL,
              `created_date` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
              `modified_date` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
              PRIMARY KEY (`id`)
            )
        " );
        queryExecute( "
            INSERT INTO `countries` (`id`, `name`, `created_date`, `modified_date`) VALUES (1, 'United States', '2017-07-28 02:07:00', '2017-07-28 02:07:00')
        " );
        queryExecute( "
            INSERT INTO `countries` (`id`, `name`, `created_date`, `modified_date`) VALUES (2, 'Argentina', '2017-07-29 03:07:00', '2017-07-29 03:07:00')
        " );
        queryExecute( "
            CREATE TABLE `users` (
              `id` int(11) NOT NULL AUTO_INCREMENT,
              `username` varchar(50) NOT NULL,
              `first_name` varchar(50) NOT NULL,
              `last_name` varchar(50) NOT NULL,
              `password` varchar(100) NOT NULL,
              `country_id` int(11) NOT NULL,
              `created_date` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
              `modified_date` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
              PRIMARY KEY (`id`)
            )
        " );
        queryExecute( "
            INSERT INTO `users` (`id`, `username`, `first_name`, `last_name`, `password`, `country_id`, `created_date`, `modified_date`) VALUES (1, 'elpete', 'Eric', 'Peterson', '5F4DCC3B5AA765D61D8327DEB882CF99', 1, '2017-07-28 02:06:36', '2017-07-28 02:06:36')
        " );
        queryExecute( "
            INSERT INTO `users` (`id`, `username`, `first_name`, `last_name`, `password`, `country_id`, `created_date`, `modified_date`) VALUES (2, 'johndoe', 'John', 'Doe', '5F4DCC3B5AA765D61D8327DEB882CF99', 2, '2017-07-28 02:07:16', '2017-07-28 02:07:16');
        " );
        queryExecute( "
            CREATE TABLE `my_posts` (
              `post_pk` int(11) NOT NULL AUTO_INCREMENT,
              `user_id` int(11) NOT NULL,
              `body` text NOT NULL,
              `created_date` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
              `modified_date` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
              PRIMARY KEY (`post_pk`)
            )
        " );
        queryExecute( "
            INSERT INTO `my_posts` (`post_pk`, `user_id`, `body`, `created_date`, `modified_date`) VALUES (1, 1, 'My awesome post body', '2017-07-28 02:07:00', '2017-07-28 02:07:00')
        " );
        queryExecute( "
            INSERT INTO `my_posts` (`post_pk`, `user_id`, `body`, `created_date`, `modified_date`) VALUES (2, 1, 'My second awesome post body', '2017-07-28 02:07:36', '2017-07-28 02:07:36')
        " );
        queryExecute( "
            CREATE TABLE `tags` (
              `id` int(11) NOT NULL AUTO_INCREMENT,
              `name` varchar(50) NOT NULL,
              PRIMARY KEY (`id`)
            )
        " );
        queryExecute( "INSERT INTO `tags` (`id`, `name`) VALUES (1, 'programming')" );
        queryExecute( "INSERT INTO `tags` (`id`, `name`) VALUES (2, 'music')" );
        queryExecute( "
            CREATE TABLE `my_posts_tags` (
              `post_pk` int(11) NOT NULL,
              `tag_id` int(11) NOT NULL,
              PRIMARY KEY (`post_pk`, `tag_id`)
            )
        " );
        queryExecute( "INSERT INTO `my_posts_tags` (`post_pk`, `tag_id`) VALUES (1, 1)" );
        queryExecute( "INSERT INTO `my_posts_tags` (`post_pk`, `tag_id`) VALUES (1, 2)" );
        queryExecute( "INSERT INTO `my_posts_tags` (`post_pk`, `tag_id`) VALUES (2, 1)" );
        queryExecute( "INSERT INTO `my_posts_tags` (`post_pk`, `tag_id`) VALUES (2, 2)" );
    }
}
