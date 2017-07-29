component {
    
    this.name = "quick";
    this.author = "";
    this.webUrl = "https://github.com/elpete/quick";
    this.dependencies = [ "qb" ];
    this.cfmapping = "quick";

    function configure() {
        settings = {
            defaultAttributeCasing = "none"
        };
    }
}