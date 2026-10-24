package main

import rego.v1

# Testa se a regra 'deny' funciona quando o Dockerfile não tem USER
test_deny_when_no_user if {
    # Simula um cenário onde não há comando 'user' no input
    mock_input := [{"Cmd": "from", "Value": ["python:3.14"]}]
    
    # Verifica se a mensagem esperada está contida dentro do conjunto 'deny'
    "dockerfile sem instrução USER: o container rodaria como root" in deny with input as mock_input
}

# Teste para imagem não aprovada
test_deny_unapproved_registry if {
    mock_input := [
        {"Cmd": "from", "Value": ["ubuntu:22.04"]},
        {"Cmd": "user", "Value": ["appuser"]}
    ]
    some msg in deny with input as mock_input
    startswith(msg, "[GOVERNANCA]")
}