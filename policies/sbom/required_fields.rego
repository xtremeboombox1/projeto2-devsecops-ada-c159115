package sbom_policy

import rego.v1

# Definição dos campos fundamentais exigidos em cada artefato pelo plano de governança do curso
required_artifact_fields := ["id", "name", "version", "type"]

# Exceções de licença revisadas manualmente.
# O Syft não extrai a licença destes pacotes (METADATA só traz o classifier),
# mas a licença real foi verificada e é conhecida. A exceção vale apenas
# para a versão exata listada.
license_exceptions := {
    {"name": "jinja2", "version": "3.1.6", "license": "BSD-3-Clause"},
}

is_license_excepted(artifact) if {
    some exception in license_exceptions
    exception.name == lower(artifact.name)
    exception.version == artifact.version
}

# 1. Validação de Assinatura/Origem do Relatório
deny contains msg if {
    not input.descriptor.name == "syft"
    msg := "[SBOM CRÍTICO] Falha de Integridade: O arquivo submetido não possui a assinatura digital do Syft."
}

# 2. Validação de Rastreabilidade do Esquema
deny contains msg if {
    input.descriptor.name == "syft"
    not input.schema.version
    msg := "[SBOM COMPLIANCE] O campo obrigatório 'schema.version' está ausente nos metadados do inventário."
}

# 3. Auditoria de Dados Estruturados dos Artefatos
deny contains msg if {
    some artifact in input.artifacts
    some field in required_artifact_fields
    not artifact[field]
    
    # Fallback seguro para capturar o nome do componente caso o campo 'name' falhe
    art_name := object.get(artifact, "name", "Componente-Nao-Identificado")
    msg := sprintf("[SBOM COMPLIANCE] O artefato '%s' violou o padrão corporativo: campo '%s' está ausente.", [art_name, field])
}

# 4. Controle de Risco de Licenças de Terceiros
deny contains msg if {
    some artifact in input.artifacts
    artifact.type == "python"

    # Ignora componentes internos da biblioteca padrão (como o binário do interpretador)
    not artifact.name == "Python"

    # O Syft mapeia a ausência de licenças declaradas como uma lista vazia []
    count(artifact.licenses) == 0

    # Ignora apenas pacotes com exceção aprovada (nome + versão)
    not is_license_excepted(artifact)

    msg := sprintf("[SBOM LICENÇA] Alto Risco Legal: A dependência '%s' (versão %s) não possui informações de licença mapeadas.", [artifact.name, artifact.version])
}
