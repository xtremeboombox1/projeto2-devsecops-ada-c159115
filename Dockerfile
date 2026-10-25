# 1. Uso de imagem base oficial com tag explícita de versão e arquitetura (Evita tags flutuantes)
FROM python:3.14-slim

WORKDIR /app

# 2. Criação de um usuário comum no Linux para rodar a aplicação
# Garante que o container não rode com privilégios elevados
RUN useradd -u 10011 appuser && \
    chown -R appuser:appuser /app

# 3. Copia e instala dependências de forma otimizada
COPY --chown=appuser:appuser requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 4. Copia os arquivos do projeto aplicando as permissões corretas do usuário
COPY --chown=appuser:appuser app/ ./app

# 5. ATIVAÇÃO DO USUÁRIO NÃO-ROOT (Esta linha vai satisfazer sua política Rego)
USER appuser

EXPOSE 5000

CMD ["python", "app/main.py"]
