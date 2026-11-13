{ config, pkgs, nixgl, inputs, ... }:

{
  imports = [ ./modules/nixvim.nix ./modules/doom.nix ];

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

    # cuda maintainers
    settings = {
      extra-substituters = [
        "https://cache.nixos-cuda.org"
      ];
      extra-trusted-public-keys = [
        "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
      ];
    };

    # secrets
    extraOptions = ''
      !include ${config.home.homeDirectory}/.config/nix/secrets.conf
    '';
    # Maps 'nixpkgs' in the CLI to your flake's nixpkgs input
    registry.nixpkgs.flake = inputs.nixpkgs;
  };

  # ── nh: garbage collection ───────────────────────────────────────────
  # Replaces the built-in nix.gc with nh's cleaner.
  programs.nh = {
    enable = true;
    flake = "${config.home.homeDirectory}/.config/home-manager";
    clean = {
      enable = true;
      dates = "daily";
      extraArgs = "--keep 3";
    };
  };

  nixpkgs.config.allowUnfree = true;

  # ── NixGL integration for GPU/OpenGL access ───────────────────────
  # Wraps programs so Nix-built apps can find the host GPU libraries.
  # On WSL2 the NVIDIA GPU is reached via Mesa's D3D12 driver (/dev/dxg),
  # not the native proprietary driver, so "mesa" is the correct wrapper
  # here — the "nvidia" wrapper needs /proc/driver/nvidia which WSL2 lacks.
  # (CUDA/NVENC still use the GPU directly via /usr/lib/wsl/lib.)
  targets.genericLinux.nixGL = {
    packages = nixgl.packages;
    defaultWrapper = "mesa";
  };

  # ── Packages ─────────────────────────────────────────────────────────
  home.packages = with pkgs; [
    # misc
    fd
    jq
    lazygit
    fastfetch
    tree
    wl-clipboard

    # nix language
    nixd
    nixpkgs-fmt

    # cleaning
    bleachbit

    # FEM packages
    (config.lib.nixGL.wrap gmsh)
    python313Packages.meshio

    # containers orchestration
    docker-compose
    podman-compose
    podman-tui
    apptainer

    # Tools for handling container images
    skopeo # Great for copying container images to tarballs
    dive # Useful for inspecting docker/OCI image layers

    # development environemnt
    devenv
    devbox
    openmpi

    # kubernetes
    openshift
    kubectl
    jfrog-cli

    # local models
    ollama-cuda
    open-webui
    ffmpeg

    # ── GUI: Vivaldi with proprietary codecs ─────────────────────────
    (vivaldi.override {
      proprietaryCodecs = true;
      enableWidevine    = true;
      commandLineArgs   = [
        # WSL exposes /dev/dxg, not the /dev/dri nodes Chromium's native
        # Wayland backend probes. WSLg provides XWayland as the fallback.
        "--ozone-platform=x11"

        # Disable native GPU rendering to prevent the /dev/dri crash
        "--disable-gpu"
        "--disable-software-rasterizer"

        # (Optional) Fixes blurry fonts in WSLg for some users
        "--force-device-scale-factor=1"
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

    EDITOR = "nvim";
    VISUAL = "nvim";
    SUDO_EDITOR = "nvim";

    BROWSER = "wslview";

    # Prefer Wayland while retaining X11 fallback. WSLg supplies its
    # display, audio, and runtime-directory connection variables.
    XDG_SESSION_TYPE = "wayland";
    GDK_BACKEND = "wayland,x11"; # GTK apps prefer Wayland, fall back to X11
    QT_QPA_PLATFORM = "wayland;xcb"; # Qt apps same

    # ── VA-API for NVIDIA GPU in WSL2 ────────────────────────────────
    # WSL2 exposes the GPU through Mesa's D3D12 VAAPI backend (NVIDIA does
    # not provide a native VA-API driver under WSL2).
    # Setting LIBVA_DRIVER_NAME=d3d12 tells libva to use that backend.
    # MESA_D3D12_DEFAULT_ADAPTER_NAME=NVIDIA ensures it picks the right
    # adapter when multiple GPUs are present on the Windows host.
    LIBVA_DRIVER_NAME = "d3d12";
    MESA_D3D12_DEFAULT_ADAPTER_NAME = "NVIDIA";
    VTK_SMP_IMPLEMENTATION_NAME = "TBB";

    # SSL / Certificates
    SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
    SSL_CERT_DIR = "/etc/ssl/certs";
    CURL_CA_BUNDLE = "/etc/ssl/certs/ca-certificates.crt";
    REQUESTS_CA_BUNDLE = "/etc/ssl/certs/ca-certificates.crt";
    NODE_EXTRA_CA_CERTS = "/etc/ssl/certs/ca-certificates.crt";

    # Nix
    NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
    NIX_PATH = "nixpkgs=flake:nixpkgs";

    # aider variables
    OLLAMA_API_BASE = "http://127.0.0.1:11434";
  };

  home.shellAliases = {
    # ── WSL / Rosen SSH ──
    win-ssh = "/mnt/c/Windows/System32/OpenSSH/ssh.exe";
    win-scp = "/mnt/c/Windows/System32/OpenSSH/scp.exe";
    win-sftp = "/mnt/c/Windows/System32/OpenSSH/sftp.exe";

    # cluster
    start-pageant = ''(cd /mnt/c && cmd.exe /c "start pageant.exe --openssh-config %userprofile%\\.ssh\\pageant.conf")'';
    linuxphys02 = ''(cd /mnt/c && cmd.exe /c "ssh -F %userprofile%\\.ssh\\pageant.conf linuxphys02.roseninspection.net")'';

    # ── Quick reload ──
    s = "source $HOME/.bashrc";

    # ── Docker / Podman ──
    nuke-docker = "docker rm -f $(docker ps -aq) 2>/dev/null; docker system prune -a --volumes -f";
    nuke-podman = "podman system reset -f";

    # ── Nix convenience ──
    nix-flake-up = "nix flake update --flake ~/.config/home-manager";
    nix-up = "nh home switch -c vkolli --no-update-lock-file";
    nix-dry = "home-manager build --flake ~/.config/home-manager#vkolli --recreate-lock-file --no-write-lock-file";

    # scoop update
    scoop-up = "powershell.exe -Command 'scoop update *; scoop cleanup *; scoop cache rm *'";

    # scoop zed path
    zed = "/mnt/c/Users/vkolli/scoop/apps/zed/current/bin/zed";
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

    initExtra = ''
      set -o vi

      # fzf **<Tab> completion: use fd (skips .git, respects .gitignore, no symlink following)
      _fzf_compgen_path() { fd --hidden --exclude .git . "$1"; }
      _fzf_compgen_dir() { fd --type d --hidden --exclude .git . "$1"; }

      # ── up-all function ──
      up-all() {
        echo "--- Updating Windows Scoop Packages ---"
        powershell.exe -Command "scoop update *; scoop cleanup *; scoop cache rm *"

        echo "--- Updating Windows Chocolatey Packages ---"
        powershell.exe -Command "choco upgrade all -y"

        echo -e "\n--- Updating Debian (Nala) ---"
        sudo nala update
        sudo nala upgrade -y
        sudo apt-get autoremove -y

        echo -e "\n--- ALL UPDATES COMPLETE ---"
        exec bash
      }
    '';
  };

  # ── Starship prompt ──────────────────────────────────────────────────
  # Replaces the entire PS1 / color_prompt / debian_chroot / xterm title
  # block from your old .bashrc.  Starship handles all of that.
  programs.starship = {
    enable = true;
    settings = {
      directory = {
        truncation_length = 0; # 0 = never truncate
        truncate_to_repo = false; # don't stop at the git repo root
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
    package = (pkgs.btop.override {
      cudaSupport = true;
    }).overrideAttrs (oldAttrs: {
      nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
      postFixup = (oldAttrs.postFixup or "") + ''
        wrapProgram $out/bin/btop \
          --prefix LD_LIBRARY_PATH : /usr/lib/wsl/lib
      '';
    });
    settings = {
      color_theme = "dracula";
      theme_background = false;
      shown_boxes = "cpu mem proc gpu0";
      show_gpu_info = "Auto";
    };
  };

  # ── direnv ─────────────────────────────────────────────────────────────
  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    nix-direnv.enable = true; # caches nix shells so they don't rebuild every time
  };

  # ── fuzzy finder  ─────────────────────────────────────────────────────────────
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    defaultCommand = "fd --type f --hidden --exclude .git";
    defaultOptions = [ "--height 40%" "--border" "--scheme=path" "--tiebreak=pathname,length" ];
    fileWidget.command = "fd --type f --hidden --exclude .git";
    fileWidget.options = [ "--preview 'bat --color=always --line-range :200 {}'" ];
    changeDirWidget.command = "fd --type d --hidden --exclude .git";
    historyWidget.command = ""; # Ctrl-R belongs to atuin
  };

  # ── atuin shell history ──────────────────────────────────────────────
  programs.atuin = {
    enable = true;
    enableBashIntegration = true;
    flags = [ "--disable-up-arrow" ];
    settings = {
      filter_mode = "global";
      search_mode = "fuzzy";
      style = "full";
      auto_sync = false;
      sync.records = false;
      enter_accept = true;
      keymap_mode = "vim-insert";
      search.filters = [ "global" "directory" "session" "workspace" ];
    };
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

    flavors = {
      catppuccin-mocha = "${pkgs.fetchFromGitHub {
        owner = "yazi-rs";
        repo = "flavors";
        rev = "38c08d8eb9ea0d28c8c911a249a08f27ba2151ac";
        hash = "sha256-lITDt1QvL54u6gbJiGixPyP6lk72f3rkiNPDrUg6G8I=";
      }}/catppuccin-mocha.yazi";
    };

    theme.flavor = {
      dark = "catppuccin-mocha";
      light = "catppuccin-mocha";
    };

    settings = {
      manager = {
        show_hidden = true;
      };

      opener = {
        nvim-tab = [
          { run = ''wt.exe -w 0 new-tab wsl.exe -d "$WSL_DISTRO_NAME" --cd "$PWD" -- bash -lc nvim''; orphan = true; desc = "nvim (directory - new tab)"; }
        ];
        terminal-tab = [
          { run = ''wt.exe -w 0 new-tab wsl.exe -d "$WSL_DISTRO_NAME" --cd "$PWD"''; orphan = true; desc = "Terminal (directory - new tab)"; }
        ];
        vscode = [
          { run = "code -n ."; orphan = true; desc = "VS Code"; }
        ];
        windows = [
          { run = ''explorer.exe "$(wslpath -w "$1")"''; orphan = true; desc = "Windows default app"; }
        ];
        zed = [
          { run = ''/mnt/c/Users/zed/current/bin/zed "$(wslpath -w "$PWD")"''; orphan = true; desc = "Zed"; }
        ];
      };

      open = {
        prepend_rules = [
          { mime = "image/*"; use = [ "windows" "reveal" ]; }
          { mime = "video/*"; use = [ "windows" "reveal" ]; }
          { mime = "audio/*"; use = [ "windows" "reveal" ]; }
          { mime = "application/pdf"; use = [ "windows" "reveal" ]; }
          { url = "*.{doc,docx,xls,xlsx,ppt,pptx,odt,ods,odp,vsdx,msg}"; use = [ "windows" "reveal" ]; }
          { url = "*/"; use = [ "terminal-tab" "nvim-tab" "vscode" "zed" "edit" "open" "reveal" ]; }
          { url = "*"; use = [ "terminal-tab" "nvim-tab" "vscode" "edit" "open" "reveal" ]; }
        ];
      };
    };
  };

  # ── Git ────────────────────────────────────────────────────────────
  # No global user/credential settings here on purpose: this repo's identity
  # and GitHub credential helper are scoped below via includeIf so they only
  # apply inside ~/.config/home-manager and never leak into corporate repos.
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "Vasu Kolli";
        email = "vkolli@rosen-group.com";
      };
      init.defaultBranch = "master";
      pull.rebase = true;
      push.autoSetupRemote = true;

      includeIf."gitdir:~/.config/home-manager/".path = "~/.config/git/personal";

      # Avoids repeated credential prompts against TFS (tfs.roseninspection.net) over HTTPS
      http.emptyauth = true;

      # Corporate Azure DevOps/TFS auth via Windows Git Credential Manager
      credential."https://dev.azure.com" = {
        authority = "aad";
        azreposCredentialType = "oauth";
        helper = "/mnt/c/Program Files/Git/mingw64/bin/git-credential-manager.exe";
        msauthUseBroker = "true";
        provider = "azure-repos";
        useHttpPath = "true";
      };

      lfs."https://dev.azure.com".locksverify = "true";
    };
  };

  # ── Personal Git identity + credentials (used only in home-manager repo) ──
  home.file.".config/git/personal".text = ''
    [user]
      name  = Vasu Kolli
      email = vasukolli23@gmail.com

    # Store GitHub credentials so you don't type the token every time
    [credential "https://github.com"]
      helper = store
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

  # ── Aider Chat (AI assistant) ─────────────────────────────────────────
  programs.aider-chat = {
    enable = true;
    package = pkgs.aider-chat-full;
    settings = {
      code-theme = "monokai";
      dark-mode = true;
    };
  };

  # ── opencode ────────────────────────────────────────────
  programs.opencode = {
    enable = true;

    # Core runtime configuration (opencode.json)
    settings = {
      autoupdate = false;
      share = "disabled";
      default_agent = "plan";

      # 1. Set your default model here so OpenCode knows to use it
      model = "qwen3.8:27b-mtp-q4_K_M";

      permission = {
        "bash" = "ask";
        "edit" = "ask";
      };
      lsp = true;
      formatter = true;

      # 2. The provider block MUST be inside settings
      provider = {
        ollama = {
          # OpenCode uses the AI SDK to connect to OpenAI-compatible endpoints
          npm = "@ai-sdk/openai-compatible";
          name = "Ollama (Local)";

          # 3. options and models MUST be inside the ollama block
          options = {
            # The /v1 is strictly required for the OpenAI compatibility layer
            baseURL = "http://127.0.0.1:11434/v1";
          };

          # Explicitly declare your local models here
          models = {
            "qwen3.8:27b-mtp-q4_K_M" = {
              name = "qwen3.8:27b-mtp-q4_K_M";
            };
          };
        }; # <--- ollama block closes here now
      };
    };

    # Terminal UI configuration (tui.json)
    tui = {
      theme = "one-dark";
      mouse = true;
      attention = {
        enabled = true;
        notifications = true;
      };
    };
  };
  # ── background services ────────────────────────────────────────────
  systemd.user.services.ollama = {
    Unit = {
      Description = "Ollama AI Service";
      After = [ "network.target" ];
    };
    Service = {
      # Points to the Nix-installed ollama binary
      ExecStart = "${pkgs.ollama-cuda}/bin/ollama serve";
      Restart = "always";
      RestartSec = "3";
      # Optional: Add any environment variables you want here
      Environment = [
        "OLLAMA_HOST=127.0.0.1:11434"
        "LD_LIBRARY_PATH=/usr/lib/wsl/lib"
      ];
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  systemd.user.services.open-webui = {
    Unit = {
      Description = "Open WebUI for Ollama";
      # This ensures Open WebUI waits for Ollama to start first
      After = [ "ollama.service" ];
      Wants = [ "ollama.service" ];
    };
    Service = {
      # Run the open-webui binary
      ExecStart = "${pkgs.open-webui}/bin/open-webui serve";
      Restart = "always";
      RestartSec = "5";
      Environment = [
        # Point it to your local Ollama
        "OLLAMA_BASE_URL=http://127.0.0.1:11434"
        # The port you will use to access it from Windows (default is 8080)
        "PORT=8080"
        # %h is systemd shorthand for your home directory.
        # This saves your chat history safely in ~/.local/share/open-webui
        "DATA_DIR=%h/.local/share/open-webui"
      ];
    };
    Install = { WantedBy = [ "default.target" ]; };
  };
}
