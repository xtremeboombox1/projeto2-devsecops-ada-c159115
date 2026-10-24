package sbom_policy

import rego.v1

# Teste 1: Valida o bloqueio caso um formato inválido seja submetido
test_fail_invalid_descriptor if {
    mock_input := {"bomFormat": "CycloneDX"}
    some msg in deny with input as mock_input
    contains(msg, "[SBOM CRÍTICO]")
}

# Teste 2: Garante o bloqueio caso falte um metadado crítico em um pacote
test_fail_missing_artifact_metadata if {
    mock_input := {
        "descriptor": {"name": "syft", "version": "1.54.1"},
        "schema": {"version": "16.1.11"},
        "artifacts": [
            {
                "id": "flask-id-01",
                "name": "flask",
                # Omitindo o campo 'version' de propósito para disparar o compliance
                "type": "python",
                "licenses": [{"value": "BSD-3-Clause"}]
            }
        ]
    }
    some msg in deny with input as mock_input
    contains(msg, "campo 'version' está ausente")
}

# Teste 3: Simula o disparo do alerta de risco de licença para pacotes legados
test_fail_missing_python_license if {
    mock_input := {
        "descriptor": {"name": "syft", "version": "1.54.1"},
        "schema": {"version": "16.1.11"},
        "artifacts": [
            {
                "id": "e5af85f2c439dacb",
                "name": "flask",
                "version": "2.2.2",
                "type": "python",
                "licenses": [] # Lista vazia disparando a Regra 4
            }
        ]
    }
    some msg in deny with input as mock_input
    contains(msg, "[SBOM LICENÇA] Alto Risco Legal")
}

# Teste 4: Valida o cenário ideal de aprovação e conformidade do pipeline
test_success_compliant_report if {
    mock_input := {
        "descriptor": {"name": "syft", "version": "1.54.1"},
        "schema": {"version": "16.1.11"},
        "artifacts": [
            {
                "id": "94560623e1919951",
                "name": "click",
                "version": "8.5.0",
                "type": "python",
                "licenses": [{"value": "BSD-3-Clause"}]
            }
        ]
    }
    count(deny) == 0 with input as mock_input
}
