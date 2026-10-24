import sys
import ast
import pkgutil
import importlib.util

# =====================================================================
# PATCH DE COMPATIBILIDADE PARA PYTHON 3.14+
# Mantém bibliotecas antigas de 2022 funcionando sem atualizar o código
# =====================================================================

# 1. Correção para o modulo 'pkgutil' ausente no Flask antigo
if not hasattr(pkgutil, "get_loader"):
    def _get_loader(module_name):
        try:
            spec = importlib.util.find_spec(module_name)
            return spec.loader if spec else None
        except Exception:
            return None
    pkgutil.get_loader = _get_loader

# 2. Correção para o modulo 'ast.Str' removido no Python 3.14 (usado pelo Werkzeug)
if not hasattr(ast, "Str"):
    # Recria dinamicamente a classe Str herdando do Constant moderno
    class ModernStr(ast.Constant):
        def __init__(self, s, *args, **kwargs):
            super().__init__(value=s, *args, **kwargs)
            self.s = s
    ast.Str = ModernStr

# =====================================================================
# CÓDIGO DA API FLASK MÍNIMA (Inalterado)
# =====================================================================
from flask import Flask, jsonify

app = Flask(__name__)

@app.route("/", methods=["GET"])
def home():
    return jsonify({
        "status": "success",
        "message": "API Flask minima rodando para testes de seguranca"
    }), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
