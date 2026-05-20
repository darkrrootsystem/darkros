{ config, pkgs, lib, polymc, ... }:

let
  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec "$@"
  '';

  myMinimalTheme = pkgs.stdenv.mkDerivation {
    name = "grub-minimal-black";
    src = ./grub-theme;
    nativeBuildInputs = [ pkgs.grub2 ];
    installPhase = ''
      mkdir -p $out
      cp theme.txt $out/
      grub-mkfont -s 16 -o $out/font.pf2 ${pkgs.nerd-fonts.jetbrains-mono}/share/fonts/truetype/JetBrainsMonoNerdFont-Regular.ttf
      sed -i 's/JetBrainsMono 16/JetBrains Mono Regular 16/g' $out/theme.txt
    '';
  };
in
{
  imports = [ ./hardware-configuration.nix ];

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  nixpkgs = {
    config.allowUnfree = true;
    overlays = [ polymc.overlay ];
  };

  boot = {
    loader = {
      grub = {
        enable = true;
        efiSupport = true;
        device = "nodev";
        useOSProber = true;
        default = "saved";
        extraConfig = "GRUB_SAVEDEFAULT=true";
        splashImage = null;
        theme = myMinimalTheme;
        gfxmodeBios = "auto";
        gfxmodeEfi = "auto";
      };
      timeout = 1;
      efi.canTouchEfiVariables = true;
    };
    kernelParams = [ 
      "mem_sleep_default=deep"
      "acpi_enforce_resources=lax" 
      "btusb.enable_autosuspend=n"
      "usbcore.autosuspend=-1"
      "btusb.disable_sc_for_fake_csr=1"
      "usbcore.quirks=33fa:0010:g"
    ];
    kernelModules = [ "i2c-dev" "i2c-i801" "ch341" ];
  };

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    interfaces.eno1.wakeOnLan.enable = true;
  };

  time.timeZone = "Europe/Kyiv";

  i18n = {
    defaultLocale = "uk_UA.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "uk_UA.UTF-8";
      LC_IDENTIFICATION = "uk_UA.UTF-8";
      LC_MEASUREMENT = "uk_UA.UTF-8";
      LC_MONETARY = "uk_UA.UTF-8";
      LC_NAME = "uk_UA.UTF-8";
      LC_NUMERIC = "uk_UA.UTF-8";
      LC_PAPER = "uk_UA.UTF-8";
      LC_TELEPHONE = "uk_UA.UTF-8";
      LC_TIME = "uk_UA.UTF-8";
    };
  };

  console.keyMap = "ua-utf";

  hardware = {
    enableAllFirmware = true;
    i2c.enable = true;
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings.General = {
        Enable = "Source,Sink,Media,Socket";
        ControllerMode = "bredr"; 
        Experimental = true;
      };
    };
    nvidia = {
      open = true;
      modesetting.enable = true;              
      powerManagement = {
        enable = true;
        finegrained = true;
      };
      prime = {
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:14:0:0";
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        sync.enable = false;
      };
    };
    nvidia-container-toolkit = {
      enable = true;
    };
  };

  users.users.darkr = {
    isNormalUser = true;
    extraGroups = [ "libvirtd" "wheel" "networkmanager" "i2c" "input" "dialout" "docker" ];
    shell = pkgs.zsh;
  };

  programs = {
    zsh.enable = true;
    zsh.autosuggestions.enable = true;
    zsh.syntaxHighlighting.enable = true;
    niri.enable = true;
    steam.enable = true;
    gamemode.enable = true;
    dconf.enable = true;
    virt-manager.enable = true;
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };
  };

  virtualisation = {
    libvirtd.enable = true;
    docker = {
      enable = true;
      extraOptions = "--gpus=all";
    };
  };

  services = {
    xserver.videoDrivers = [ "modesetting" "nvidia" ];
    hardware.openrgb.enable = true;
    dbus.packages = [ pkgs.gsettings-desktop-schemas ];
    
    ollama = {
      enable = true;
      package = pkgs.ollama-cuda;
      environmentVariables = {
        OLLAMA_KEEP_ALIVE = "0s";
        OLLAMA_NUM_PARALLEL = "1";
      };
    };

    udev = {
      packages = [ pkgs.openrgb ];
      extraRules = ''
        KERNEL=="hidraw*", ATTRS{idVendor}=="373e", MODE="0666", TAG+="uaccess", GROUP="users"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="373e", MODE="0666", TAG+="uaccess", GROUP="users"
        KERNEL=="hidraw*", ATTRS{idVendor}=="258a", MODE="0666", TAG+="uaccess", GROUP="users"
        KERNEL=="js*", ATTRS{idVendor}=="1209", ATTRS{idProduct}=="4f54", MODE="0666", GROUP="input"
        KERNEL=="event*", ATTRS{idVendor}=="1209", ATTRS{idProduct}=="4f54", MODE="0666", GROUP="input"
        KERNEL=="js*", ATTRS{idVendor}=="33fa", MODE="0666", GROUP="input"
        KERNEL=="ttyUSB*", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", MODE="0666", GROUP="dialout"
      '';
    };
  };

  environment = {
    sessionVariables = {
      TERMINAL = "kitty";
      EDITOR = "nvim";
      NIXOS_OZONE_WL = "1";
      GTK_THEME = "Adwaita-dark"; 
      QT_STYLE_OVERRIDE = "adwaita-dark";
      GTK_APPLICATION_PREFER_DARK_THEME = "1";
      QT_QPA_PLATFORM = "wayland";
      MOZ_ENABLE_WAYLAND = "1";
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_DATA_DIRS = [ "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}" ];
    };
    systemPackages = with pkgs; [
      nvidia-offload playerctl unrar ironbar jq socat hyperhdr
      kitty anyrun git zsh p7zip yazi mpv
      xwayland-satellite vulkan-loader vulkan-tools mpvpaper 
      btop nvtopPackages.nvidia firefox tor-browser element-desktop obs-studio 
      pavucontrol kdePackages.kdenlive ayugram-desktop viber libreoffice
      dosfstools blender protonup-rs polymc.packages.x86_64-linux.default
      wl-clipboard brightnessctl fd ntfs3g exfatprogs github-cli 
      zoom-us nmap openssl ethtool qbittorrent usbutils jdk25
      ripgrep gnumake gcc unzip lua-language-server nil nixpkgs-fmt
      pkg-config rustc cargo rust-analyzer unar kicad kanata
      gnome-themes-extra gsettings-desktop-schemas glib
      adwaita-icon-theme alsa-lib
    ];
  };

  fonts = {
    fontconfig.enable = true;
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      nerd-fonts.hack
      nerd-fonts.symbols-only
      noto-fonts
      liberation_ttf
      dejavu_fonts
      corefonts
    ];
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "*";
  };

  specialisation = {
    GPU.configuration = {
      system.nixos.tags = [ "GPU" ];
      hardware.nvidia.prime = {
        sync.enable = lib.mkForce true;
        offload.enable = lib.mkForce false;
        offload.enableOffloadCmd = lib.mkForce false;
      };
      hardware.nvidia.powerManagement.finegrained = lib.mkForce false;
    };
    CPU.configuration = {
      system.nixos.tags = [ "CPU" ];
      services.xserver.videoDrivers = lib.mkForce [ "modesetting" ];
      hardware.nvidia.modesetting.enable = lib.mkForce false;
      hardware.nvidia.prime = {
        offload.enable = lib.mkForce false;
        sync.enable = lib.mkForce false;
      };
      hardware.nvidia.powerManagement.finegrained = lib.mkForce false;

      hardware.nvidia-container-toolkit.suppressNvidiaDriverAssertion = true;
    };
  };

  system = {
    stateVersion = "25.11";
    activationScripts.installGenesisNvim = {
      text = ''
        if [ ! -d "/home/darkr/.config/nvim" ]; then
          ${pkgs.git}/bin/git clone https://github.com/Zproger/GenesisNvim.git /home/darkr/.config/nvim
          chown -R darkr:users /home/darkr/.config/nvim
        fi
      '';
    };
  };
}
