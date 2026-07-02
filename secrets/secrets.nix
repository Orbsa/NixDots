# Map of which public keys can decrypt which secrets.
# Keys: SSH public keys (ssh-rsa AAAA... or ssh-ed25519 AAAA...)
# You can also use age-specific keys generated with: age-keygen -o ~/.config/agenix/key.txt
let
  eric = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQClXfQoD+dIihb2UJr7oeEmA5EI38lpariK1vHhfM3lzXTNTXm6kODS+L98fxs3izdL8VEDgoPBrJaOx9WL10+zKuUVIw63jd38+o3NUcm8dgXbYndkb0ro6aYS+iyiqWl4rUi9h44N9KGDtEvL7khBQ1C80Vb+xyga2+WH/vTMEadsG51Pcasaq0X6eBFERMWMI0tXny7Poh+9M5q++8CCJ/0FX0Hr8t3/jcKrhi4ICJNSfvz7ywrPFzLMXB9AFcXKUz3D59awKfpeDZQV68S6tgVhkvOEkh6cXSfS6o3+qX7sb0u+PNYSCOLlZCxf4Bdz5K4Y9J8TnryrVf9UN95/BqCVXpnkEp+HziNp0kdCyJaxkaqbpBjnB0kJIsK1IjqpcznFnV9wF3BNVg1bmltl10Wf2hbewp7dCbaVx2z1gi3SECdlOVt+e0eUAoabsLXvwQddks6Yh1/PxCTwwS932bREONn60iKiOOMwywEyRqJvaS2WqEaTATueFr5ryhc= eric@Stratos";
  plix = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEFq8NmYOesRogqynVLo8JeC23ngAeEnAunJTQa2U+HQ";
  vix = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO461RmMqoswR0EtWTuNw+ijr6JMPJnbIZzWbKRaZilF root@vix.novalocal";
  enix = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPLgQIEf+fYu8A1nvYt0SLVSZcXd5YhZGoUVxxyGRa0D root@enix";
in
{
  "admin-password.age".publicKeys = [ eric plix ];
  "ts-auth-key.age".publicKeys = [ eric plix enix vix ];
  "plex-url.age".publicKeys = [ eric vix ];
  "maxmind-license-key.age".publicKeys = [ eric vix ];
  "dkim-s20190117248.key".publicKeys = [ eric vix ];
  "dkim-s20231213814.key".publicKeys = [ eric vix ];
  "dkim-s20231213516.key".publicKeys = [ eric vix ];
  "beszel-token.age".publicKeys = [ eric plix enix vix ];
}
