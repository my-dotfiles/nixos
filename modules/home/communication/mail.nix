{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myHome.communication.mail;
  maildir = "${config.home.homeDirectory}/Mail";
  pass = name: "cat ${config.sops.secrets.${name}.path}";
  bidirectionalMbsync = {
    enable = true;
    create = "both";
    remove = "both";
    expunge = "both";
    extraConfig.channel.Sync = "Full";
  };
in
{
  options.myHome.communication.mail.enable = lib.mkEnableOption "Emacs mu4e mail frontend";

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
          mbsync = bidirectionalMbsync // {
            patterns = [
              "INBOX"
              "*"
            ];
          };
          msmtp.enable = true;
          mu.enable = true;
        };

        icloud = {
          address = "superyurikon@icloud.com";
          userName = "superyurikon@icloud.com";
          realName = "Yurikon";
          passwordCommand = pass "mail-icloud-passwd";

          imap = {
            host = "imap.mail.me.com";
            port = 993;
            tls.enable = true;
          };
          smtp = {
            host = "smtp.mail.me.com";
            port = 587;
            tls.useStartTls = true;
          };
          mbsync = bidirectionalMbsync // {
            patterns = [
              "INBOX"
              "Archive"
              "Deleted Messages"
              "Drafts"
              "Junk"
              "Sent Messages"
            ];
          };
          msmtp.enable = true;
          mu.enable = true;
        };
        qq = {
          address = "3166701497@qq.com";
          userName = "3166701497@qq.com";
          realName = "郑彦文";
          passwordCommand = pass "mail-qq-passwd";

          imap = {
            host = "imap.qq.com";
            port = 993;
            tls.enable = true;
          };
          smtp = {
            host = "smtp.qq.com";
            port = 465;
            tls.enable = true;
          };
          mbsync = bidirectionalMbsync // {
            patterns = [
              "INBOX"
              "Archive"
              "Deleted Messages"
              "Drafts"
              "Junk"
              "Sent Messages"
              "!其他文件夹"
            ];
          };
          msmtp.enable = true;
          mu.enable = true;
        };

        netease163 = {
          address = "yuriisbest@163.com";
          userName = "yuriisbest@163.com";
          realName = "Yurikon";
          passwordCommand = pass "mail-163-passwd";

          imap = {
            host = "imap.163.com";
            port = 993;
            tls.enable = true;
          };
          smtp = {
            host = "smtp.163.com";
            port = 465;
            tls.enable = true;
          };

          mbsync = {
            # 163 lists mailboxes but currently rejects SELECT for them.
            enable = false;
          };
          msmtp.enable = true;
          mu.enable = true;
        };
      };
    };
    services.mbsync = {
      enable = true;
      frequency = "*-*-* *:0/10:00";
      postExec = "${pkgs.mu}/bin/mu index";
    };
  };
}
