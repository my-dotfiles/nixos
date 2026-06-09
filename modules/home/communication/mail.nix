{ config, lib, pkgs, ... }:

let
  cfg = config.myHome.communication.mail;
  maildir = "${config.home.homeDirectory}/Mail";
  pass = name: "cat ${config.sops.secrets.${name}.path}";
in
{
  option.myHome.communication.mail.enable =
    lib.mkEnableOption "Emacs mu4e mail frontend";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      isync
      msmtp
      mu
      w3m
    ];
    programs.mbsync.enable = true;
    programs.msmtp.enable = true;
    programs.mu.enable = true;

    accounts.email = {
      maildirBasePath = maildir;

      accounts = {
        gmail = {
          primary = true;
          address = "h6606797@gmail.com";
          userName = "h6606797@gmail.com";
          realName = "Yurikon";
          passwordCommand = pass "mail-gmail-passwd";

          imap = {
            host = "imap.gmail.com";
            port = 993;
            tls.enable = true;
          };
          smtp = {
            host = "smtp.gmail.com";
            port = 465;
            tls.enable = true;
          };
          mbsync = {
            enable = true;
            create = "both";
            expunge = "both";
            patterns = [ "*" ];
          };
          msmtp.enable = true;
          mu.enable = true;
        };
      };
    };
    services.mbsync = {
      enable = true;
      frequency = "*;0/10";
      postExec = "${pkgs.mu}/bin/mu index";
    };
  };
}
