{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "matterbridge";
  version = "1.26.2";

  src = fetchFromGitHub {
    owner = "bibanon";
    repo = "matterbridge";
    tag = "v${version}";
    hash = "sha256-7F0cAdnxUt2to+zhf/gtobbvPX1NnSpsLKbxy059CB0=";
  };

  subPackages = [ "." ];

  vendorHash = null;

  meta = {
    description = "Simple bridge between Mattermost, IRC, XMPP, Gitter, Slack, Discord, Telegram, Rocket.Chat, Hipchat(via xmpp), Matrix and Steam";
    homepage = "https://github.com/bibanon/matterbridge/";
    license = with lib.licenses; [ asl20 ];
    maintainers = with lib.maintainers; [ SuperSandro2000 ];
    mainProgram = "matterbridge";
  };
}
