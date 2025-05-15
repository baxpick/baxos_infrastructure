locals {

    # Containers
    # ##########

    # Build container (constants)
    container_defaults = {
        cpu      = "1.5"
        memory   = "6"
        common_env_vars = {
            "IS_STARTED_FROM_BAXOS_BUILD_CONTAINER" = "YES"
            "FOLDER_ROOT"                           = "/build/retro/projects"
            "ARG_COMPRESSION"                       = "NONE"
            "GIT_ROOT_CREDS"                        = var.BAXOS_SRC_GIT_ROOT_CREDS
            "GIT_ROOT"                              = var.BAXOS_SRC_GIT_ROOT
            "GIT_PROJECT_SUFFIX"                     = var.BAXOS_SRC_GIT_PROJECT_SUFFIX
            "BUILD_SCRIPT"                          = "/build/retro/projects/loader/build_from_container.sh"
        }
    }

    # Build container (container specific values)
    containers = [
        {
            platform    = "cpc"
            card        = "rsf3"      
        },
        {
            platform    = "cpc"
            card        = "sf3"
        },
        {
            platform    = "enterprise"
            card        = "rsf3"
        },
        {
            platform    = "enterprise"
            card        = "sf3"
        }
    ]

    # Web server container config
    web_server = {
        name  = "web-server"
        image = "mcr.microsoft.com/azurelinux/base/nginx:1.25" 
        cpu   = "1.0"
        memory= "2.0"
        port  = 80
    }
}
