{ config, pkgs, nixgl, lazyvim, ... }:

{
  imports = [
    lazyvim.homeManagerModules.default
  ];

  home.username = "vkolli";
  home.homeDirectory = "/home/vkolli";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
  targets.genericLinux.enable = true;
  fonts.fontconfig.enable = true;

  xdg.enable = true;
  xdg.mime.enable = true;

  nix = {
    package = pkgs.nix;

    # experimental features enable
    settings.experimental-features = [ "nix-command" "flakes" ];

    # secrets
    extraOptions = ''
      !include ${config.home.homeDirectory}/.config/nix/secrets.conf
    '';

    # optimize (reuse) common package - elmerfem does not like it
    settings.auto-optimise-store = false;

    # garbage collection
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than +3";
    };
    
    # substituters
    settings = {
      extra-substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      extra-trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };

  nixpkgs.config.allowUnfree = true;

  # ── NixGL integration for GPU/OpenGL access ───────────────────────
  # Wraps programs so Nix-built Mesa can find the host GPU libraries.
  # "mesa" is the correct wrapper for Intel iGPU (free/open drivers).
  targets.genericLinux.nixGL = {
    packages = nixgl.packages;
    defaultWrapper = "mesa";
  };

  # ── Packages ─────────────────────────────────────────────────────────
  home.packages = with pkgs; [
    # misc
    fd
    lazygit
    fastfetch

    # cleaning
    bleachbit

    # editors
    gedit

    # latex
    texliveFull

    # FEM packages
    (config.lib.nixGL.wrap gmsh)
    python313Packages.meshio

    # containers orchestration
    docker-compose
    podman-compose
    podman-tui
    apptainer

    # Tools for handling container images
    skopeo      # Great for copying container images to tarballs
    dive        # Useful for inspecting docker/OCI image layers

    # file managers
    kdePackages.dolphin
    kdePackages.konsole

    # development environemnt
    devenv

    # kubernetes
    openshift
    kubectl
    jfrog-cli

    # ── GUI: Vivaldi with proprietary codecs ─────────────────────────
    (vivaldi.override {
      proprietaryCodecs = true;
      enableWidevine    = true;
      commandLineArgs   = [
        "--ozone-platform-hint=auto"
        "--use-gl=egl"
        "--ignore-gpu-blocklist"
        "--enable-gpu-rasterization"
        "--enable-zero-copy"
        "--enable-features=VaapiVideoDecodeLinuxGL,VaapiVideoEncoder,CanvasOopRasterization,UseOzonePlatform"
        "--enable-webrtc-pipewire-capturer"
      ];
    })

    # VA-API diagnostics: run `vainfo` to check decoder profiles
    libva-utils
  ];

  # ── Environment Variables (shell-agnostic) ───────────────────────────
  # These end up in your login profile so every program inherits them,
  # not just interactive bash sessions.
  home.sessionVariables = {
    GCC_COLORS = "error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01";

    # default editor
    EDITOR  = "nvim";
    VISUAL  = "nvim";
    BROWSER = "wslview";

    # WSLg / Wayland support
    DISPLAY            = ":0";
    WAYLAND_DISPLAY    = "wayland-0";
    XDG_RUNTIME_DIR    = "/run/user/1000";   # replace 1000 with your actual UID
    XDG_SESSION_TYPE   = "wayland";
    GDK_BACKEND        = "wayland,x11";      # GTK apps prefer Wayland, fall back to X11
    QT_QPA_PLATFORM    = "wayland;xcb";      # Qt apps same
    PULSE_SERVER       = "unix:/mnt/wslg/runtime-dir/pulse/native"; # audio via WSLg

    # ── VA-API for Intel GPU in WSL2 ─────────────────────────────────
    # WSL2 exposes your Intel GPU through Mesa's D3D12 VAAPI backend.
    # Setting LIBVA_DRIVER_NAME=d3d12 tells libva to use that backend.
    # MESA_D3D12_DEFAULT_ADAPTER_NAME=Intel ensures it picks the right
    # adapter when multiple GPUs are present on the Windows host.
    LIBVA_DRIVER_NAME               = "d3d12";
    MESA_D3D12_DEFAULT_ADAPTER_NAME = "Intel";
    VTK_SMP_IMPLEMENTATION_NAME     = "TBB";

    # SSL / Certificates
    SSL_CERT_FILE       = "/etc/ssl/certs/ca-certificates.crt";
    SSL_CERT_DIR        = "/etc/ssl/certs";
    NIX_SSL_CERT_FILE   = "/etc/ssl/certs/ca-certificates.crt";
    CURL_CA_BUNDLE      = "/etc/ssl/certs/ca-certificates.crt";
    REQUESTS_CA_BUNDLE  = "/etc/ssl/certs/ca-certificates.crt";
    NODE_EXTRA_CA_CERTS = "/etc/ssl/certs/ca-certificates.crt";
  };

  home.sessionVariablesExtra = ''
    export LD_LIBRARY_PATH="/usr/lib/wsl/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  '';

  home.shellAliases = {
    # ── WSL / Rosen SSH ──
    win-ssh     = "/mnt/c/Windows/System32/OpenSSH/ssh.exe";
    win-scp     = "/mnt/c/Windows/System32/OpenSSH/scp.exe";
    win-sftp    = "/mnt/c/Windows/System32/OpenSSH/sftp.exe";

    # cluster
    start-pageant = ''(cd /mnt/c && cmd.exe /c "start pageant.exe --openssh-config %userprofile%\\.ssh\\pageant.conf")'';
    linuxphys02 = "/mnt/c/Windows/System32/OpenSSH/ssh.exe linuxphys02.roseninspection.net";

    # ── Quick reload ──
    s = "source $HOME/.bashrc";

    # ── Docker / Podman ──
    nuke-docker = "docker rm -f $(docker ps -aq) 2>/dev/null; docker system prune -a --volumes -f";
    nuke-podman = "podman system reset -f";

    # ── Nix convenience ──
    nix-up = "nix flake update --flake ~/.config/home-manager && home-manager switch --flake ~/.config/home-manager#vkolli";

    # scoop update
    scoop-up = "powershell.exe -Command 'scoop update *; scoop cleanup *; scoop cache rm *'";
  };

  # ── Bash ─────────────────────────────────────────────────────────────
  programs.bash = {
    enable = true;
    enableCompletion = true;

    historyControl = [ "ignoreboth" ];
    historySize = 10000;
    historyFileSize = 20000;

    shellOptions = [
      "histappend"
      "checkwinsize"
      "globstar"
    ];

    # Everything that can't be expressed declaratively goes here.
    # This is appended at the end of .bashrc.
    initExtra = ''
      # ── up-all function ──
      up-all() {
        # echo "--- Updating Windows Scoop Packages ---"
        # powershell.exe -Command "scoop update *; scoop cleanup *; scoop cache rm *"

        echo "--- Updating Windows Chocolatey Packages ---"
        powershell.exe -Command "choco upgrade all -y"

        echo -e "\n--- Updating Debian (Nala) ---"
        sudo nala update
        sudo nala upgrade -y
        sudo apt-get autoremove -y

        echo -e "\n--- Updating Nix Packages ---"
        nix flake update --flake /home/vkolli/.config/home-manager
        home-manager switch --flake /home/vkolli/.config/home-manager#vkolli

        echo -e "\n--- ALL UPDATES COMPLETE ---"
        exec bash
      }'';
  };

  # ── Lazyvim + Neovim ──────────────────────────────────────────────
  programs.lazyvim = {
    enable = true;
    extras = {
    lang.nix.enable = true;
    lang.python = {
      enable = true;
      installDependencies = true;        # Install ruff
      installRuntimeDependencies = true; # Install python3
      };
    };
  };

  # ── Starship prompt ──────────────────────────────────────────────────
  # Replaces the entire PS1 / color_prompt / debian_chroot / xterm title
  # block from your old .bashrc.  Starship handles all of that.
  programs.starship = {
    enable = true;
    settings = {
      directory = {
        truncation_length   = 0;     # 0 = never truncate
        truncate_to_repo    = false; # don't stop at the git repo root
        fish_style_pwd_dir_length = 0; # disable fish-style shortening
      };
    };
  };
  # ── Eza ──────────────────────────────────────────────────────────────
  # Replaces: alias ls="eza --icons", alias ll, alias la, alias l,
  # and the dircolors / ls --color=auto block.
  programs.eza = {
    enable = true;
    icons = "auto";
    enableBashIntegration = true;
    extraOptions = [
      "--group-directories-first"
      "--header"
      "--all"
    ];
  };

  # ── Zoxide ───────────────────────────────────────────────────────────
  # Replaces: eval "$(zoxide init bash)"
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
  };

  # ── Btop ─────────────────────────────────────────────────────────────
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "dracula";
      theme_background = false;
      shown_boxes = "cpu mem proc";
    };
  };

  # ── direnv ─────────────────────────────────────────────────────────────
  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    nix-direnv.enable = true;  # caches nix shells so they don't rebuild every time
  };

  # ── fuzzy finder  ─────────────────────────────────────────────────────────────
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    defaultOptions = [ "--height 40%" "--border" ];
  };

  # ── bat  ─────────────────────────────────────────────────────────────
  # replaces cat
  programs.bat = {
    enable = true;
    config = {
      style = "numbers,changes,header";
    };
  };

  # ── ripgrep  ─────────────────────────────────────────────────────────────
  programs.ripgrep.enable = true;

  # ── yazi terminal file manager  ─────────────────────────────────────────
  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    shellWrapperName = "y";

    settings = {
      manager = {
        show_hidden = true;
      };

      opener = {
        vscode = [
          { run = "code -n ."; orphan = true; desc = "code"; }
        ];
      };

      open = {
        prepend_rules = [
          # "url" is the correct field, not "name"
          # "*/" matches directories
          { url = "*/"; use = [ "vscode" "edit" "open" "reveal" ]; }
          # "*" matches everything else
          { url = "*";  use = [ "vscode" "edit" "open" "reveal" ]; }
        ];
      };
    };
  };

  # ── Git ────────────────────────────────────────────────────────────
  programs.git = {
    enable = true;

    settings = {
      user = {
        name  = "Vasu Kolli";
        email = "vkolli@rosen-group.com";
      };
      init.defaultBranch = "master";
      pull.rebase = true;
      push.autoSetupRemote = true;

      includeIf."gitdir:~/.config/home-manager/".path = "~/.config/git/personal";

      # Store GitHub credentials so you don't type the token every time
      credential."https://github.com" = {
        helper = "store";
      };
    };
  };

  # ── Personal Git identity (used only in home-manager repo) ─────────
  home.file.".config/git/personal".text = ''
    [user]
      name  = Vasu Kolli
      email = vasukolli23@gmail.com
  '';

  # ── SSH config (corporate TFS only, no GitHub) ─────────────────────
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      "*" = {
        AddKeysToAgent = "yes";
      };
    };
  };
}
