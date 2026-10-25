package sbom_policy

import rego.v1

# Monta um SBOM válido do Syft com os artefatos informados
mk_input(artifacts) := {
    "descriptor": {"name": "syft"},
    "schema": {"version": "16.1.11"},
    "artifacts": artifacts,
}

mk_pkg(name, version, licenses) := {
    "id": sprintf("id-%s", [name]),
    "name": name,
    "version": version,
    "type": "python",
    "licenses": licenses,
}

# --- Caso feliz ---
test_valid_sbom_has_no_denies if {
    msgs := deny with input as mk_input([
        mk_pkg("flask", "2.2.2", [{"value": "BSD-3-Clause"}]),
    ])
    count(msgs) == 0
}

# --- Regra 1: assinatura do Syft ---
test_denies_non_syft_descriptor if {
    msgs := deny with input as {
        "descriptor": {"name": "outra-ferramenta"},
        "schema": {"version": "16.1.11"},
        "artifacts": [],
    }
    count(msgs) == 1
}

# --- Regra 2: schema.version ---
test_denies_missing_schema_version if {
    msgs := deny with input as {
        "descriptor": {"name": "syft"},
        "schema": {},
        "artifacts": [],
    }
    count(msgs) == 1
}

# --- Regra 3: campos obrigatórios do artefato ---
test_denies_artifact_missing_id if {
    msgs := deny with input as mk_input([{
        "name": "flask",
        "version": "2.2.2",
        "type": "python",
        "licenses": [{"value": "BSD-3-Clause"}],
    }])
    count(msgs) == 1
}

# --- Regra 4: licenças ---
test_denies_python_without_license if {
    msgs := deny with input as mk_input([
        mk_pkg("pacote-desconhecido", "1.0.0", []),
    ])
    count(msgs) == 1
}

test_allows_python_with_license if {
    msgs := deny with input as mk_input([
        mk_pkg("flask", "2.2.2", [{"value": "BSD-3-Clause"}]),
    ])
    count(msgs) == 0
}

test_ignores_python_interpreter_without_license if {
    msgs := deny with input as mk_input([
        mk_pkg("Python", "3.12.0", []),
    ])
    count(msgs) == 0
}

# --- Exceções de licença ---
test_allows_excepted_jinja2_without_license if {
    msgs := deny with input as mk_input([
        mk_pkg("jinja2", "3.1.6", []),
    ])
    count(msgs) == 0
}

test_denies_jinja2_with_different_version if {
    msgs := deny with input as mk_input([
        mk_pkg("jinja2", "9.9.9", []),
    ])
    count(msgs) == 1
}