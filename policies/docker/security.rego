package main

import rego.v1

approved_prefixes := ["python:", "docker.io/library/", "cgr.dev/chainguard/"]
from_cmds := [c | some c in input; c.Cmd == "from"]
user_cmds := [c | some c in input; c.Cmd == "user"]

# 1- regra para negar se o dockerfile não definir um usuário não-root
deny contains msg if {
    count(user_cmds) == 0
    msg := "dockerfile sem instrução USER: o container rodaria como root"
}

# 2- exigir imagem de um registry ou prefixo aprovado
deny contains msg if {
    some cmd in from_cmds
    image := cmd.Value[0]

    # Verifica se a imagem não começa com nenhum dos prefixos aprovados
    not any_prefix_match(image, approved_prefixes)
    msg := sprintf("[GOVERNANCA] falha: a imagem base '%s' não vem provém de um registry/prefixo aprovado !", [image])
}

any_prefix_match(image, prefixes) if {
    some prefix in prefixes
    startswith(image, prefix)
}

# 3- bloquear o uso da tag 'latest' ou tags genéricas
deny contains msg if {
    some cmd in from_cmds
    image := cmd.Value[0]

    # Valida se a imagem usa 'latest'
    is_latest_tag(image)
    msg := sprintf("[COMPLIANCE] falha: a imagem '%s' está usando a tag 'latest' ou nenhuma tag específica", [image])
}

is_latest_tag(image) if endswith(image, ":latest")
is_latest_tag(image) if not contains(image, ":")