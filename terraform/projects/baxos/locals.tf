locals {

    # Containers
    # ##########

    # Build container (constants)
    build_container_defaults = {
        cpu      = "0.5"
        memory   = "1"
        common_env_vars = {
            "IS_STARTED_FROM_BAXOS_BUILD_CONTAINER" = "YES"
            "FOLDER_ROOT"                           = "/build/retro/projects"
            "ARG_COMPRESSION"                       = "NONE"
            "ARG_TMTNET_ID"                         = "3013"
            "PROJECT_GIT_REPO"                      = var.BAXOS_SRC_PROJECT_GIT_REPO
            "BUILD_SCRIPT"                          = "/build/retro/projects/loader/build_from_container.sh"
        }
    }

    # Build container (container specific values)
    build_containers = {
        "cpc-rsf3"       = { platform = "cpc",          card = "rsf3" }
        "cpc-sf3"        = { platform = "cpc",          card = "sf3" }
        "enterprise-rsf3"= { platform = "enterprise",   card = "rsf3" }
        "enterprise-sf3" = { platform = "enterprise",   card = "sf3" }
    }

    # Web server container config
    web_server = {
        name  = "web-server"
        image = "mcr.microsoft.com/azurelinux/base/nginx:1" 
        cpu   = "0.5"
        memory= "1.0"
        port  = 80
    }
}
