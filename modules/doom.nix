{ config, pkgs, lib, ... }:

{
  programs.emacs = {
    enable = true;
    package = pkgs.emacs-pgtk;
  };

  home.packages = with pkgs; [
    git
    ripgrep
    fd
    # vterm build
    cmake
    gnumake
    libtool
    gcc
    shellcheck
  ];

  home.sessionPath = [ "${config.xdg.configHome}/emacs/bin" ];

  # Doom is mutable and lives outside the Nix store; config stays in ~/.config/doom.
  home.activation.cloneDoom = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -d "${config.xdg.configHome}/emacs" ]; then
      run ${pkgs.git}/bin/git clone --depth 1 https://github.com/doomemacs/doomemacs "${config.xdg.configHome}/emacs"
    fi
  '';
}
