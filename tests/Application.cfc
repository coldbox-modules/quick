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

    this.datasources[ "quick" ] = {
        class: "org.gjt.mm.mysql.Driver",
        connectionString: "jdbc:mysql://localhost:3306/quick?useUnicode=true&characterEncoding=UTF-8&useLegacyDatetimeCode=true",
        username: "root",
        password: "encrypted:6e47cf9870bede1b4191fa42a1c264441a64822b62a00488"
    };

    this.datasource = "quick";

    function onRequestStart() {
        // applicationStop();
        setUpDatabase();
    }

    private function setUpDatabase() {
        queryExecute( "DROP DATABASE IF EXISTS quick" );
        queryExecute( "CREATE DATABASE quick" );
        queryExecute( "USE quick" );
        queryExecute( "
            CREATE TABLE `quick`.`users`  (
              `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT,
              `username` varchar(50) NOT NULL,
              `first_name` varchar(50) NOT NULL,
              `last_name` varchar(50) NOT NULL,
              `password` varchar(100) NOT NULL,
              `created_date` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
              `modified_date` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP(0),
              PRIMARY KEY (`id`)
            )
        " );
        queryExecute( "
            INSERT INTO `quick`.`users` (`id`, `username`, `first_name`, `last_name`, `password`, `created_date`, `modified_date`) VALUES (1, 'elpete', 'Eric', 'Peterson', '5F4DCC3B5AA765D61D8327DEB882CF99', '2017-07-28 02:06:36', '2017-07-28 02:06:36')
        " );
        queryExecute( "
            INSERT INTO `quick`.`users` (`id`, `username`, `first_name`, `last_name`, `password`, `created_date`, `modified_date`) VALUES (2, 'johndoe', 'John', 'Doe', '5F4DCC3B5AA765D61D8327DEB882CF99', '2017-07-28 02:07:16', '2017-07-28 02:07:16');
        " );
        queryExecute( "
            CREATE TABLE `quick`.`my_posts`  (
              `post_pk` int(11) UNSIGNED NOT NULL AUTO_INCREMENT,
              `user_id` int(11) UNSIGNED NOT NULL,
              `body` text NOT NULL,
              `created_date` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
              `modified_date` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP(0),
              PRIMARY KEY (`post_pk`)
            )
        " );
        queryExecute( "
            INSERT INTO `quick`.`my_posts`(`post_pk`, `user_id`, `body`, `created_date`, `modified_date`) VALUES (1, 1, 'My awesome post body', '2017-07-28 02:07:00', '2017-07-28 02:07:00')
        " );
        queryExecute( "
            INSERT INTO `quick`.`my_posts`(`post_pk`, `user_id`, `body`, `created_date`, `modified_date`) VALUES (2, 1, 'My second awesome post body', '2017-07-28 02:07:36', '2017-07-28 02:07:36')
        " );
        queryExecute( "
            CREATE TABLE `quick`.`tags`  (
              `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT,
              `name` varchar(50) NOT NULL,
              PRIMARY KEY (`id`)
            )
        " );
        queryExecute( "INSERT INTO `quick`.`tags` (`id`, `name`) VALUES (1, 'programming')" );
        queryExecute( "INSERT INTO `quick`.`tags` (`id`, `name`) VALUES (2, 'music')" );
        queryExecute( "
            CREATE TABLE `quick`.`my_posts_tags`  (
              `post_pk` int(11) UNSIGNED NOT NULL,
              `tag_id` int(11) UNSIGNED NOT NULL,
              PRIMARY KEY (`post_pk`, `tag_id`)
            )
        " );
        queryExecute( "INSERT INTO `quick`.`my_posts_tags` (`post_pk`, `tag_id`) VALUES (1, 1)" );
        queryExecute( "INSERT INTO `quick`.`my_posts_tags` (`post_pk`, `tag_id`) VALUES (1, 2)" );
        queryExecute( "INSERT INTO `quick`.`my_posts_tags` (`post_pk`, `tag_id`) VALUES (2, 1)" );
        queryExecute( "INSERT INTO `quick`.`my_posts_tags` (`post_pk`, `tag_id`) VALUES (2, 2)" );
    }
}
