# Map of which public keys can decrypt which secrets.
# Keys: SSH public keys (ssh-rsa AAAA... or ssh-ed25519 AAAA...)
# You can also use age-specific keys generated with: age-keygen -o ~/.config/agenix/key.txt
let
  eric = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQClXfQoD+dIihb2UJr7oeEmA5EI38lpariK1vHhfM3lzXTNTXm6kODS+L98fxs3izdL8VEDgoPBrJaOx9WL10+zKuUVIw63jd38+o3NUcm8dgXbYndkb0ro6aYS+iyiqWl4rUi9h44N9KGDtEvL7khBQ1C80Vb+xyga2+WH/vTMEadsG51Pcasaq0X6eBFERMWMI0tXny7Poh+9M5q++8CCJ/0FX0Hr8t3/jcKrhi4ICJNSfvz7ywrPFzLMXB9AFcXKUz3D59awKfpeDZQV68S6tgVhkvOEkh6cXSfS6o3+qX7sb0u+PNYSCOLlZCxf4Bdz5K4Y9J8TnryrVf9UN95/BqCVXpnkEp+HziNp0kdCyJaxkaqbpBjnB0kJIsK1IjqpcznFnV9wF3BNVg1bmltl10Wf2hbewp7dCbaVx2z1gi3SECdlOVt+e0eUAoabsLXvwQddks6Yh1/PxCTwwS932bREONn60iKiOOMwywEyRqJvaS2WqEaTATueFr5ryhc= eric@Stratos";
  plix = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEFq8NmYOesRogqynVLo8JeC23ngAeEnAunJTQa2U+HQ";
  vix = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO461RmMqoswR0EtWTuNw+ijr6JMPJnbIZzWbKRaZilF root@vix.novalocal";
  enix = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAH1z2fkUrrPCnjid5jWzxma75K7Gr8hVl9JP4BGIvLo root@enix";
  enix-rsa = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDbxT5hgH/eGt2QP9EDU1msErfZNjDgUrjdRVc+9CbIgssq4ZkRT120Ax898RnPaEUo0ziYeci/eMKsIJt/cHnNEdC3J5DF7xBtbqizMHinif66xLSWhunjoSx3PimRk9ejxhhgC3w6mbR1hF/x83a+7yPHldJOUSm0upnlHEjDuTuCdbhWxMfLGPvrgjGxUMhmjo7tr7Xvhzo88ws6KcG95VzWe670MZgciLF5Z8l0tYVZOe+Okt5ypHjIs31adctHoqLUkh0mqSHKTgB0ngVYzoYWMvSGfLBZ49H+eZeKTGh2fTuOmrSbFybPbKDbAglD4QPs78d8xPZco8pBuDDRO8IdzyXc6xBsqLTBQqeew83fNseHCAsSTJc9OvrUTZxtNNtfKKWvQ7UO0Wh5/PCQ/h7WmP1rchGl69zEABQhMuNKU+TqOtpfi1Z5JubAhxRcerYA+aSmfdGYW90V0F8nyXzXWO9LhwUtPhnEK8JJh6SL1XuVVgX4Rd0kHxSjmQU= root@enix";
in
{
  "admin-password.age".publicKeys = [ eric plix ];

  "plex-url.age".publicKeys = [ eric vix ];
  "maxmind-license-key.age".publicKeys = [ eric vix ];
  "dkim-s20190117248.key".publicKeys = [ eric vix ];
  "dkim-s20231213814.key".publicKeys = [ eric vix ];
  "dkim-s20231213516.key".publicKeys = [ eric vix ];
  "beszel-token.age".publicKeys = [ eric plix enix enix-rsa vix ];
}
