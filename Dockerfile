# 1. Uso de imagem base genérica e tag flutuante (Gera alertas de segurança)
# Adaptado para usar a sua versão do Python (3.14)
FROM python:3.14

WORKDIR /app

# 2. Copia o requirements.txt da raiz para instalar as dependências vulneráveis
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 3. Copia o conteúdo da sua pasta app/ para dentro do container
COPY app/ ./app

EXPOSE 5000

# 4. Executa como ROOT implicitamente (Inseguro - Falha na política Rego)
# Aponta exatamente para o seu arquivo main.py
CMD ["python", "app/main.py"]
